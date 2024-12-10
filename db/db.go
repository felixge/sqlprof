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
func (db *DB) loadTrace(ctx context.Context, r io.Reader) (rErr error) {
	tr, err := trace.NewReader(r)
	if err != nil {
		return err
	}

	l, err := db.loader(ctx)
	if err != nil {
		return err
	}
	defer l.Close()

	gIdx := map[trace.GoID]*gState{}
	pIdx := map[trace.ProcID]*pState{}
	for first := true; ; first = false {
		ev, err := tr.ReadEvent()
		if err == io.EOF {
			break
		} else if err != nil {
			return err
		}

		if first {
			macroSQL := fmt.Sprintf(
				`create macro rel_time_ns(abs_time_ns) AS (SELECT abs_time_ns - %v);`,
				ev.Time(),
			)
			if _, err := db.ExecContext(ctx, macroSQL); err != nil {
				return err
			}
		}

		var srcStackID uint64
		if srcStackID, err = l.Stack(ev.Stack()); err != nil {
			return err
		}

		switch ev.Kind() {
		case trace.EventStackSample:
			sample := &cpuSample{
				EndTimeNS: uint64(ev.Time()),
				StackID:   srcStackID,
				G:         ev.Goroutine(),
				P:         ev.Proc(),
				M:         ev.Thread(),
			}
			if err := l.CPUSample(sample); err != nil {
				return err
			}
		case trace.EventMetric:
			metricEv := ev.Metric()
			switch metricEv.Value.Kind() {
			case trace.ValueUint64:
				if err := l.Append(
					"metrics",
					uint64(ev.Time()),
					metricEv.Name,
					int64(metricEv.Value.Uint64()),
				); err != nil {
					return err
				}
			default:
				return fmt.Errorf("unsupported metric value kind: %v", metricEv.Value.Kind())
			}
		case trace.EventStateTransition:
			st := ev.StateTransition()
			var stackID uint64
			if stackID, err = l.Stack(st.Stack); err != nil {
				return err
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
				transition := &pTransition{
					P:          procID,
					StackID:    srcStackID,
					EndTimeNS:  uint64(ev.Time()),
					DurationNS: uint64(dt),
					SrcG:       ev.Goroutine(),
					SrcP:       ev.Proc(),
					SrcM:       ev.Thread(),
					FromState:  strings.ToLower(from.String()),
					ToState:    strings.ToLower(to.String()),
					Reason:     st.Reason,
				}
				if err := l.PTransition(transition); err != nil {
					return err
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
				transition := &gTransition{
					G:          goID,
					EndTimeNS:  uint64(ev.Time()),
					DurationNS: uint64(dt),
					SrcG:       ev.Goroutine(),
					SrcP:       ev.Proc(),
					SrcM:       ev.Thread(),
					FromState:  strings.ToLower(from.String()),
					ToState:    strings.ToLower(to.String()),
					Reason:     st.Reason,
					StackID:    stackID,
					SrcStackID: srcStackID,
				}
				if err := l.GTransition(transition); err != nil {
					return err
				}
				g.time = ev.Time()
			}
		}
	}

	if err := l.Close(); err != nil {
		return err
	}

	return nil
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
	tables := []string{
		"functions",
		"frames",
		"stack_frames",
		"raw_g_transitions",
		"p_transitions",
		"raw_cpu_samples",
		"metrics",
	}
	for _, table := range tables {
		appender, err := duckdb.NewAppenderFromConn(conn, "", table)
		if err != nil {
			return nil, err
		}
		l.appenders[table] = appender
	}
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

// GTransition appends an transition to the database.
func (l *loader) GTransition(e *gTransition) error {
	return l.appenders["raw_g_transitions"].AppendRow(
		nullableResource(e.G),
		e.FromState,
		e.ToState,
		nullableString(e.Reason),
		e.DurationNS,
		e.EndTimeNS,
		nullableStackID(e.StackID),
		nullableStackID(e.SrcStackID),
		nullableResource(e.SrcG),
		nullableResource(e.SrcM),
		nullableResource(e.SrcP),
	)
}

func (l *loader) PTransition(e *pTransition) error {
	return l.appenders["p_transitions"].AppendRow(
		nullableResource(e.P),
		e.FromState,
		e.ToState,
		e.DurationNS,
		e.EndTimeNS,
		nullableResource(e.SrcP),
		nullableResource(e.SrcG),
		nullableResource(e.SrcM),
	)
}

func (l *loader) CPUSample(s *cpuSample) error {
	return l.appenders["raw_cpu_samples"].AppendRow(
		s.EndTimeNS,
		nullableStackID(s.StackID),
		nullableResource(s.G),
		nullableResource(s.P),
		nullableResource(s.M),
	)
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
			if err = l.appenders["functions"].AppendRow(
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
			if err = l.appenders["frames"].AppendRow(
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
			if err := l.appenders["stack_frames"].AppendRow(
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

type gTransition struct {
	G          trace.GoID
	EndTimeNS  uint64
	DurationNS uint64
	SrcG       trace.GoID
	SrcP       trace.ProcID
	SrcM       trace.ThreadID
	FromState  string
	ToState    string
	Reason     string
	SrcStackID uint64
	StackID    uint64
}

type pTransition struct {
	P          trace.ProcID
	EndTimeNS  uint64
	DurationNS uint64
	SrcG       trace.GoID
	SrcP       trace.ProcID
	SrcM       trace.ThreadID
	FromState  string
	ToState    string
	Reason     string
	StackID    uint64
}

type cpuSample struct {
	EndTimeNS uint64
	StackID   uint64
	G         trace.GoID
	P         trace.ProcID
	M         trace.ThreadID
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
