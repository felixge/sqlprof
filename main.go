package main

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"embed"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/pprof/profile"
	"github.com/marcboeker/go-duckdb"
	"golang.org/x/exp/trace"
)

//go:embed schema.sql after_schema.sql
var fs embed.FS

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}

func run() error {
	ctx := context.Background()
	start := time.Now()
	defer func() {
		fmt.Printf("Elapsed: %v\n", time.Since(start))
	}()
	flag.Parse()
	inFile, err := os.Open(flag.Arg(0))
	if err != nil {
		return err
	}
	defer inFile.Close()

	db, err := initDB("trace.db")
	if err != nil {
		return err
	}

	f := &File{
		Name: flag.Arg(0),
		R:    inFile,
	}

	// if err := importGoTrace(ctx, inFile, db); err != nil {
	// 	return err
	// }
	if err := importPPROF(ctx, f, db); err != nil {
		return err
	}

	if err := fsExec(db.db, "after_schema.sql"); err != nil {
		return err
	}

	return inFile.Close()
}

type File struct {
	Name string
	R    io.Reader
}

func importPPROF(ctx context.Context, f *File, dst *DB) (rErr error) {
	conn, err := dst.connector.Connect(ctx)
	if err != nil {
		return err
	}

	var appenders []*duckdb.Appender
	defer func() {
		for _, a := range appenders {
			rErr = errors.Join(rErr, a.Close())
		}
	}()
	newAppender := func(table string) (*duckdb.Appender, error) {
		a, err := duckdb.NewAppenderFromConn(conn, "pprof", table)
		if err != nil {
			return nil, err
		}
		appenders = append(appenders, a)
		return a, nil
	}

	sampleTypes, err := newAppender("sample_types")
	if err != nil {
		return err
	}

	samples, err := newAppender("samples")
	if err != nil {
		return err
	}

	labels, err := newAppender("labels")
	if err != nil {
		return err
	}

	functions, err := newAppender("functions")
	if err != nil {
		return err
	}

	locations, err := newAppender("locations")
	if err != nil {
		return err
	}

	lines, err := newAppender("lines")
	if err != nil {
		return err
	}

	prof, err := profile.Parse(f.R)
	if err != nil {
		return err
	}

	for index, st := range prof.SampleType {
		row := []driver.Value{
			uint8(index + 1),
			st.Type,
			st.Unit,
		}
		if err := sampleTypes.AppendRow(row...); err != nil {
			return err
		}
	}

	for _, f := range prof.Function {
		row := []driver.Value{
			f.ID,
			f.Name,
			f.SystemName,
			f.Filename,
			f.StartLine,
		}
		if err := functions.AppendRow(row...); err != nil {
			return err
		}
	}

	var labelID uint64
	var sampleID uint64
	for _, s := range prof.Sample {
		sampleID++
		locationIDs := make([]uint64, len(s.Location))
		for i, l := range s.Location {
			locationIDs[i] = l.ID

			row := []driver.Value{
				l.ID,
				l.Mapping.ID,
				l.Address,
				l.IsFolded,
			}
			if err := locations.AppendRow(row...); err != nil {
				return err
			}

			for _, ln := range l.Line {
				row := []driver.Value{
					l.ID,
					ln.Function.ID,
					ln.Line,
					ln.Column,
				}
				if err := lines.AppendRow(row...); err != nil {
					return err
				}
			}
		}

		labelIDs := make([]uint64, 0, len(s.Label)+len(s.NumLabel))
		for key, vals := range s.Label {
			for _, val := range vals {
				labelID++
				if err := labels.AppendRow(labelID, sampleID, key, val, int64(0), ""); err != nil {
					return err
				}
				labelIDs = append(labelIDs, labelID)
			}
		}

		row := []driver.Value{
			f.Name,
			sampleID,
			locationIDs,
			s.Value,
			labelIDs,
		}
		if err := samples.AppendRow(row...); err != nil {
			return err
		}
	}

	_ = prof
	return nil
}

func importGoTrace(ctx context.Context, r io.Reader, dst *DB) (rErr error) {
	tr, err := trace.NewReader(r)
	if err != nil {
		return err
	}

	conn, err := dst.connector.Connect(ctx)
	if err != nil {
		return err
	}

	var appenders []*duckdb.Appender
	defer func() {
		for _, a := range appenders {
			rErr = errors.Join(rErr, a.Close())
		}
	}()
	newAppender := func(table string) (*duckdb.Appender, error) {
		a, err := duckdb.NewAppenderFromConn(conn, "", table)
		if err != nil {
			return nil, err
		}
		appenders = append(appenders, a)
		return a, nil
	}

	events, err := newAppender("events")
	if err != nil {
		return err
	}

	for {
		ev, err := tr.ReadEvent()
		if err == io.EOF {
			break
		} else if err != nil {
			return err
		}

		// TODO: would be nice to use nil for several of the values below
		// but when I try I get errors like this:
		// the first row cannot contain null values (column 12)
		row := []driver.Value{
			int64(ev.Time()),      // 0 time
			ev.Kind().String(),    // 1 kind
			int64(ev.Thread()),    // 2 m
			int64(ev.Proc()),      // 3 p
			int64(ev.Goroutine()), // 4 g
			"",                    // 5 resource
			"",                    // 6 label
			"",                    // 7 metric_name
			uint64(0),             // 8 metric_value
			"",                    // 9 range_name
			"",                    // 10 range_scope
			[]string(nil),         // 11 range_attributes
			uint64(0),             // 12 task_id
			uint64(0),             // 13 task_pid
			"",                    // 14 task_type
			"",                    // 15 log_category
			"",                    // 16 log_message
		}

		ev.String()
		// See ev.String() code for the origin of this logic
		switch kind := ev.Kind(); kind {
		case trace.EventMetric:
			m := ev.Metric()
			row[7] = m.Name
			row[8] = m.Value.Uint64()
		case trace.EventLabel:
			l := ev.Label()
			row[5] = l.Resource.String()
			row[6] = l.Label
		case trace.EventStateTransition:
			s := ev.StateTransition()
			row[5] = s.Resource.Kind.String()
		case trace.EventRangeBegin, trace.EventRangeActive, trace.EventRangeEnd:
			r := ev.Range()
			row[9] = r.Name
			row[10] = r.Scope.String()

			var attrs []string
			if kind == trace.EventRangeEnd {
				for _, attr := range ev.RangeAttributes() {
					attrs = append(attrs, fmt.Sprintf("%s=%d", attr.Name, attr.Value.Uint64()))
				}
			}
			row[11] = attrs
		case trace.EventTaskBegin, trace.EventTaskEnd:
			t := ev.Task()
			row[12] = uint64(t.ID)
			row[13] = uint64(t.Parent)
			row[14] = string(t.Type)
		case trace.EventRegionBegin, trace.EventRegionEnd:
			r := ev.Region()
			row[12] = uint64(r.Task)
			row[14] = r.Type
		case trace.EventLog:
			l := ev.Log()
			row[12] = uint64(l.Task)
			row[15] = l.Category
			row[16] = decodeLogMessage(l.Category, l.Message)
		}
		// 	s := ev.StateTransition()
		// 	switch s.Resource.Kind {
		// 	case trace.ResourceProc:
		// 		p := int64(s.Resource.Proc())
		// 		old, new := s.Proc()
		// 		if err := pTransitions.AppendRow(
		// 			t,
		// 			p,
		// 			int64(ev.Goroutine()),
		// 			int64(ev.Thread()),
		// 			int64(ev.Proc()),
		// 			strings.ToLower(old.String()),
		// 			strings.ToLower(new.String()),
		// 		); err != nil {
		// 			return err
		// 		}
		// 	case trace.ResourceGoroutine:
		// 		g := int64(s.Resource.Goroutine())
		// 		old, new := s.Goroutine()
		// 		if err := gTransitions.AppendRow(
		// 			t,
		// 			g,
		// 			int64(ev.Goroutine()),
		// 			int64(ev.Thread()),
		// 			int64(ev.Proc()),
		// 			strings.ToLower(old.String()),
		// 			strings.ToLower(new.String()),
		// 			strings.ToLower(s.Reason),
		// 		); err != nil {
		// 			return err
		// 		}
		// 	}
		// }

		if err := events.AppendRow(row...); err != nil {
			return err
		}
		ev.String()
		_ = ev
	}

	return nil
}

func hexEscape(s string) string {
	return "hex:" + hex.EncodeToString([]byte(s))
}

func decodeLogMessage(category, message string) string {
	if utf8.ValidString(message) {
		return message
	}
	if strings.Contains(category, "uint64") {
		return fmt.Sprintf("%d", binary.LittleEndian.Uint64([]byte(message)))
	}
	return hexEscape(message)
}

type DB struct {
	db        *sql.DB
	connector *duckdb.Connector
}

func initDB(file string) (*DB, error) {
	os.Remove(file)
	connector, err := duckdb.NewConnector(file, nil)
	if err != nil {
		return nil, err
	}

	db := sql.OpenDB(connector)
	if err := fsExec(db, "schema.sql"); err != nil {
		return nil, err
	}
	return &DB{db: db, connector: connector}, nil
}

func fsExec(db *sql.DB, file string) error {
	b, err := fs.ReadFile(file)
	if err != nil {
		return err
	}
	_, err = db.Exec(string(b))
	return err
}
