package db

import (
	"bytes"
	"context"
	"crypto/sha256"
	"database/sql"
	"database/sql/driver"
	"embed"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"

	"github.com/google/pprof/profile"
	"github.com/marcboeker/go-duckdb"
	"golang.org/x/exp/trace"
)

//go:embed schema.sql stdlib.txt
var fs embed.FS

// profileKind is a kind of profile that can be converted into a database.
type profileKind string

const (
	// profileKindTrace represents a runtime trace.
	profileKindTrace profileKind = "trace"
	// profileKindPPROF represents a pprof profile.
	profileKindPPROF profileKind = "pprof"
)

// Profile is a profile that can be converted into a database.
type Profile struct {
	Filename string
	Data     io.Reader
	Meta     json.RawMessage
}

// Create creates a new duckdb at the given path and loads the profile into it.
func Create(duckPath string, p Profile) (*DB, error) {
	db, err := Open(duckPath)
	if err != nil {
		return nil, err
	}

	b, err := fs.ReadFile("schema.sql")
	if err != nil {
		return nil, errors.Join(err, db.Close())
	} else if _, err := db.Exec(string(b)); err != nil {
		return nil, errors.Join(err, db.Close())
	} else if stdlibMacro, err := stdlibMacro(); err != nil {
		return nil, errors.Join(err, db.Close())
	} else if _, err := db.Exec(stdlibMacro); err != nil {
		return nil, errors.Join(err, db.Close())
	} else if err := insertCustomMeta(db.DB, p.Meta); err != nil {
		return nil, errors.Join(err, db.Close())
	}

	switch guessFileType(p.Filename) {
	case profileKindTrace:
		if err := db.loadTrace(context.Background(), p.Data); err != nil {
			return nil, err
		}
	case profileKindPPROF:
		if err := db.loadPPROF(context.Background(), p.Data); err != nil {
			return nil, err
		}
	default:
		return nil, fmt.Errorf("unknown profile type: %q", p.Filename)
	}
	return db, nil
}

func Open(duckPath string) (*DB, error) {
	connector, err := duckdb.NewConnector(duckPath, nil)
	if err != nil {
		return nil, err
	}

	db := &DB{
		DB:   sql.OpenDB(connector),
		path: duckPath,
		duck: connector,
	}
	return db, nil
}

func guessFileType(filename string) profileKind {
	// TODO: make this more robust.
	switch {
	case strings.HasSuffix(filename, ".pprof"):
		return profileKindPPROF
	default:
		return profileKindTrace
	}
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
		if srcStackID, err = l.Stack(traceFrameSource{ev.Stack()}); err != nil {
			return
		}

		switch ev.Kind() {
		case trace.EventStackSample:
			if err = l.Append(
				"stack_samples",
				"samples/count", // same as used by go's pprof cpu profile
				nullableUint64(srcStackID),
				1,
				uint64(ev.Time()),
				nil,
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
					nullableUint64(srcStackID),
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
			if stackID, err = l.Stack(traceFrameSource{st.Stack}); err != nil {
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
					nullableUint64(stackID),
					nullableUint64(srcStackID),
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

func (db *DB) loadPPROF(ctx context.Context, r io.Reader) (err error) {
	var prof *profile.Profile
	if prof, err = profile.Parse(r); err != nil {
		return
	}

	var l *loader
	if l, err = db.loader(ctx); err != nil {
		return
	}
	defer func() { err = errors.Join(err, l.Close()) }()

	for _, s := range prof.Sample {
		var srcStackID uint64
		if srcStackID, err = l.Stack(pprofFrameSource{s.Location}); err != nil {
			return
		}

		var labelSetID uint64
		if labelSetID, err = l.LabelSet(sampleLabelSets(s)); err != nil {
			return
		}

		for i, st := range prof.SampleType {
			if err = l.Append(
				"stack_samples",
				st.Type+"/"+st.Unit,
				nullableUint64(srcStackID),
				s.Value[i],
				nil, // time
				nullableUint64(labelSetID),
				nil, // src_g
				nil, // src_p
				nil, // src_m
			); err != nil {
				return
			}
		}
	}
	return nil
}

func sampleLabelSets(s *profile.Sample) (labels []label) {
	for key, vals := range s.Label {
		for _, val := range vals {
			labels = append(labels, label{Key: key, StrVal: val})
		}
	}
	for key, vals := range s.NumLabel {
		for i, val := range vals {
			ls := label{Key: key, NumVal: val}
			if units, ok := s.NumUnit[key]; ok && i < len(units) {
				ls.NumUnit = units[i]
			}
			labels = append(labels, ls)
		}
	}
	return
}

type traceFrameSource struct {
	stack trace.Stack
}

func (t traceFrameSource) IsNone() bool {
	return t.stack == trace.NoStack
}

func (t traceFrameSource) Frames(fn func(stackFrame) bool) bool {
	var frame stackFrame
	t.stack.Frames(func(f trace.StackFrame) bool {
		frame.StackFrame = f
		return fn(frame)
	})
	return true
}

type pprofFrameSource struct {
	locations []*profile.Location
}

func (p pprofFrameSource) IsNone() bool {
	return p.locations == nil
}

func (p pprofFrameSource) Frames(fn func(stackFrame) bool) bool {
	var frame stackFrame
	for _, loc := range p.locations {
		for i, line := range loc.Line {
			frame.StackFrame = trace.StackFrame{
				PC:   loc.Address,
				Func: line.Function.Name,
				File: line.Function.Filename,
				Line: uint64(line.Line),
			}
			frame.Inlined = inlinedYes
			if i+1 == len(loc.Line) {
				frame.Inlined = inlinedNo
			}
			if !fn(frame) {
				return false
			}
		}
	}
	return true
}

func nullableString(v string) any {
	if v == "" {
		return nil
	}
	return v
}

func nullableInlined(v inlined) any {
	switch v {
	case inlinedYes:
		return true
	case inlinedNo:
		return false
	case inlinedUnknown:
		return nil
	default:
		panic(fmt.Sprintf("unknown inlined value: %v", v))
	}
}

func nullableResource[T trace.ProcID | trace.GoID | trace.ThreadID](v T) any {
	// TODO: ideally we'd check against trace.NoGoroutine and similar consts
	// here.
	if v == -1 {
		return nil
	}
	return int64(v)
}

func nullableUint64(v uint64) any {
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
	conn        driver.Conn
	funcIdx     map[functionKey]*functionRow
	frameIdx    map[frameKey]*frameRow
	stackIdx    map[stackKey]*stack
	appenders   map[string]*duckdb.Appender
	labelSetIdx uint64
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

type frameSource interface {
	IsNone() bool
	Frames(func(stackFrame) bool) bool
}

type stackFrame struct {
	trace.StackFrame
	Inlined inlined
}

type inlined int

const (
	inlinedUnknown inlined = iota
	inlinedYes
	inlinedNo
)

func (l *loader) Stack(s frameSource) (stackID uint64, err error) {
	if s.IsNone() {
		return 0, nil
	}

	var frames []*frameRow
	s.Frames(func(f stackFrame) bool {
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
		frameKey := frameKey{Address: f.PC, Function: fn, Line: f.Line, Inlined: f.Inlined}
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
				nullableInlined(frame.Inlined), // inlined
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
		// panic("no frames, but not NoStack")
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

func (l *loader) LabelSet(ls []label) (uint64, error) {
	if len(ls) == 0 {
		return 0, nil
	}
	l.labelSetIdx++
	for _, label := range ls {
		var strVal any
		var numVal any
		if label.StrVal != "" {
			strVal = label.StrVal
		} else {
			numVal = label.NumVal
		}

		var unit any
		if label.NumUnit != "" {
			unit = label.NumUnit
		}

		if err := l.Append(
			"label_sets",
			l.labelSetIdx,
			label.Key,
			strVal,
			numVal,
			unit,
		); err != nil {
			return 0, err
		}
	}
	return l.labelSetIdx, nil
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
	Inlined  inlined
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

type label struct {
	Key     string
	StrVal  string
	NumVal  int64
	NumUnit string
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

func stdlibMacro() (string, error) {
	data, err := fs.ReadFile("stdlib.txt")
	if err != nil {
		return "", err
	}

	var values []string
	for _, line := range bytes.Split(data, []byte("\n")) {
		if len(line) == 0 {
			continue
		}
		values = append(values, fmt.Sprintf("('%s')", line))
	}
	vals := strings.Join(values, ", ")
	tmpl := `create macro is_std(func) AS (
	exists (
		select *
		from (values %s) prefixes(prefix)
		where func like prefix || '.%%'
	)
);`
	return fmt.Sprintf(tmpl, vals), nil
}

func insertCustomMeta(db *sql.DB, meta json.RawMessage) error {
	escaped := strings.ReplaceAll(string(meta), "'", "''")
	_, err := db.Exec(`create macro custom_meta() AS (select '` + escaped + `'::json);`)
	return err
}
