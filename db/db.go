package db

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"database/sql/driver"
	"embed"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"strings"

	"github.com/marcboeker/go-duckdb"
	"golang.org/x/exp/trace"
)

//go:embed schema.sql
var fs embed.FS

// ProfileKind is a kind of profile that can be converted into a database.
type ProfileKind string

const (
	// ProfileKindTrace represents a runtime trace.
	ProfileKindTrace ProfileKind = "trace"
	// ProfileKindPPROF represents a pprof profile.
	ProfileKindPPROF ProfileKind = "pprof"
)

// Profile is a profile that can be converted into a database.
type Profile struct {
	Kind ProfileKind
	Data io.Reader
}

// Create creates a new duckdb at the given path and loads the profile into it.
func Create(duckPath string, p Profile) (*DB, error) {
	switch p.Kind {
	case ProfileKindTrace:
		return createTrace(duckPath, p.Data)
	case ProfileKindPPROF:
		return nil, fmt.Errorf("not implemented: kind=%q", p.Kind)
	default:
		return nil, fmt.Errorf("invalid profile: kind=%q", p.Kind)
	}
}

func createTrace(duckPath string, r io.Reader) (*DB, error) {
	connector, err := duckdb.NewConnector(duckPath, nil)
	if err != nil {
		return nil, err
	}

	db := &DB{
		DB:   sql.OpenDB(connector),
		path: duckPath,
		duck: connector,
	}
	b, err := fs.ReadFile("schema.sql")
	if err != nil {
		return nil, errors.Join(err, db.Close())
	} else if _, err := db.Exec(string(b)); err != nil {
		return nil, errors.Join(err, db.Close())
	}
	if err := db.loadTrace(context.Background(), r); err != nil {
		return nil, errors.Join(err, db.Close())
	}
	return db, nil
}

type DB struct {
	*sql.DB
	path string
	duck *duckdb.Connector
}

// Path returns the path to the database.
func (db *DB) Path() string {
	return db.path
}

// loadTrace loads a runtime/trace from r into the database.
func (db *DB) loadTrace(ctx context.Context, r io.Reader) (err error) {
	var tr *trace.Reader
	if tr, err = trace.NewReader(r); err != nil {
		return
	}

	var l *loader
	if l, err = db.loader(ctx); err != nil {
		return
	}
	defer func() { err = errors.Join(err, l.Close()) }()

	gIdx := map[trace.GoID]*gState{}
	pIdx := map[trace.ProcID]*pState{}
	for first := true; ; first = false {
		var ev trace.Event
		if ev, err = tr.ReadEvent(); err == io.EOF {
			err = nil
			break
		} else if err != nil {
			return
		}

		if first {
			macroSQL := fmt.Sprintf(
				`create macro rel_time_ns(abs_time_ns) AS (SELECT abs_time_ns - %v);`,
				ev.Time(),
			)
			if _, err = db.ExecContext(ctx, macroSQL); err != nil {
				return
			}
		}

		var srcStackID uint64
		if srcStackID, err = l.Stack(ev.Stack()); err != nil {
			return
		}

		switch ev.Kind() {
		case trace.EventStackSample:
			if err = l.Append(
				"cpu_samples",
				uint64(ev.Time()),
				nullableStackID(srcStackID),
				nullableResource(ev.Goroutine()),
				nullableResource(ev.Proc()),
				nullableResource(ev.Thread()),
			); err != nil {
				return
			}
		case trace.EventMetric:
			metricEv := ev.Metric()
			switch metricEv.Value.Kind() {
			case trace.ValueUint64:
				if err = l.Append(
					"metrics",
					uint64(ev.Time()),
					metricEv.Name,
					int64(metricEv.Value.Uint64()),
					nullableStackID(srcStackID),
					nullableResource(ev.Goroutine()),
					nullableResource(ev.Proc()),
					nullableResource(ev.Thread()),
				); err != nil {
					return
				}
			default:
				return fmt.Errorf("unsupported metric value kind: %v", metricEv.Value.Kind())
			}
		case trace.EventStateTransition:
			st := ev.StateTransition()
			var stackID uint64
			if stackID, err = l.Stack(st.Stack); err != nil {
				return
			}
			if srcStackID == stackID {
				srcStackID = 0
			}

			// Goroutines that produce no events during a generation are listed
			// with a traceEvGoStatusStack event at the end of it. This event
			// is produced with a triggering G, M, P and has a stack but no
			// transition stack. IMO it should be the other way around, but for
			// now we work around this here. See traceEvGoStatusStack.sql test
			// in testdata/queries/invariants.txtar.sql.
			// TODO: File upstream issue and CL for this.
			if srcStackID != 0 && stackID == 0 && ev.Goroutine() == trace.NoGoroutine {
				srcStackID, stackID = stackID, srcStackID
			}

			switch st.Resource.Kind {
			case trace.ResourceProc:
				from, to := st.Proc()
				procID := st.Resource.Proc()
				p, ok := pIdx[procID]
				dt := trace.Time(0)
				if !ok {
					p = &pState{}
					pIdx[procID] = p
				} else {
					dt = ev.Time() - p.time
				}
				transition := []driver.Value{
					nullableResource(procID),
					strings.ToLower(from.String()),
					strings.ToLower(to.String()),
					uint64(dt),
					uint64(ev.Time()),
					nullableResource(ev.Proc()),
					nullableResource(ev.Goroutine()),
					nullableResource(ev.Thread()),
				}
				if err = l.Append("p_transitions", transition...); err != nil {
					return
				}
				p.time = ev.Time()
			case trace.ResourceGoroutine:
				from, to := st.Goroutine()
				goID := st.Resource.Goroutine()
				g, ok := gIdx[goID]
				dt := trace.Time(0)
				if !ok {
					g = &gState{}
					gIdx[goID] = g
				} else {
					dt = ev.Time() - g.time
				}
				transition := []driver.Value{
					nullableResource(goID),
					strings.ToLower(from.String()),
					strings.ToLower(to.String()),
					nullableString(st.Reason),
					uint64(dt),
					uint64(ev.Time()),
					nullableStackID(stackID),
					nullableStackID(srcStackID),
					nullableResource(ev.Goroutine()),
					nullableResource(ev.Thread()),
					nullableResource(ev.Proc()),
				}
				if err = l.Append("g_transitions", transition...); err != nil {
					return
				}
				g.time = ev.Time()
			}
		}
	}
	return
}

func nullableString(v string) any {
	if v == "" {
		return nil
	}
	return v
}

func nullableResource[T trace.ProcID | trace.GoID | trace.ThreadID](v T) any {
	// TODO: ideally we'd check against trace.NoGoroutine and similar consts
	// here.
	if v == -1 {
		return nil
	}
	return int64(v)
}

func nullableStackID(v uint64) any {
	if v == 0 {
		return nil
	}
	return v
}

type gState struct {
	time trace.Time
}

type pState struct {
	time trace.Time
}

func (db *DB) loader(ctx context.Context) (*loader, error) {
	l := &loader{
		funcIdx:   map[functionKey]*functionRow{},
		frameIdx:  map[frameKey]*frameRow{},
		stackIdx:  map[stackKey]*stack{},
		appenders: map[string]*duckdb.Appender{},
	}
	conn, err := db.duck.Connect(ctx)
	if err != nil {
		return nil, err
	}
	l.conn = conn
	return l, nil
}

type loader struct {
	conn      driver.Conn
	funcIdx   map[functionKey]*functionRow
	frameIdx  map[frameKey]*frameRow
	stackIdx  map[stackKey]*stack
	appenders map[string]*duckdb.Appender
}

func (l *loader) Append(table string, args ...driver.Value) (err error) {
	appender, ok := l.appenders[table]
	if !ok {
		if appender, err = duckdb.NewAppenderFromConn(l.conn, "", table); err != nil {
			return
		}
		l.appenders[table] = appender
	}
	return appender.AppendRow(args...)
}

func (l *loader) Stack(s trace.Stack) (stackID uint64, err error) {
	if s == trace.NoStack {
		return 0, nil
	}

	var frames []*frameRow
	s.Frames(func(f trace.StackFrame) bool {
		fnKey := functionKey{Name: f.Func, File: f.File}
		fn, ok := l.funcIdx[fnKey]
		if !ok {
			fn = &functionRow{FunctionID: uint64(len(l.funcIdx) + 1), functionKey: fnKey}
			l.funcIdx[fnKey] = fn
			if err = l.Append(
				"functions",
				fn.FunctionID,
				fn.Name,
				fn.File,
			); err != nil {
				return false
			}
		}
		frameKey := frameKey{Address: f.PC, Function: fn, Line: f.Line}
		frame, ok := l.frameIdx[frameKey]
		if !ok {
			frame = &frameRow{FrameID: uint64(len(l.frameIdx) + 1), frameKey: frameKey}
			l.frameIdx[frameKey] = frame
			if err = l.Append(
				"frames",
				frame.FrameID,
				frame.Address,
				frame.Function.FunctionID,
				frame.Line,
			); err != nil {
				return false
			}
		}
		frames = append(frames, frame)
		return true
	})
	if err != nil {
		return 0, err
	}

	if len(frames) == 0 {
		panic("no frames, but not NoStack")
	}
	stackKey := newStackKey(frames)
	stk, ok := l.stackIdx[stackKey]
	if !ok {
		stk = &stack{StackID: uint64(len(l.stackIdx) + 1), Frames: frames}
		l.stackIdx[stackKey] = stk
		for i, frame := range stk.Frames {
			if err := l.Append(
				"stack_frames",
				stk.StackID,
				frame.FrameID,
				i,
			); err != nil {
				return 0, err
			}
		}
	}
	return stk.StackID, nil
}

func (l *loader) Close() error {
	var err error
	for _, a := range l.appenders {
		err = errors.Join(err, a.Close())
	}
	return errors.Join(l.conn.Close(), err)
}

type frameRow struct {
	FrameID uint64
	frameKey
}

type frameKey struct {
	Address  uint64
	Function *functionRow
	Line     uint64
}

type functionRow struct {
	FunctionID uint64
	functionKey
}

type functionKey struct {
	Name string
	File string
}

type stack struct {
	StackID uint64
	Frames  []*frameRow
}

type stackKey struct {
	Lo uint64
	Hi uint64
}

// newStackKey returns a new StackKey for the given frames. The key is the
// sha256 hash of the concatenated frame ids.
func newStackKey(frames []*frameRow) stackKey {
	h := sha256.New()
	for _, frame := range frames {
		binary.Write(h, binary.LittleEndian, int64(frame.FrameID))
	}
	return stackKey{
		Lo: binary.LittleEndian.Uint64(h.Sum(nil)[:8]),
		Hi: binary.LittleEndian.Uint64(h.Sum(nil)[8:]),
	}
}
