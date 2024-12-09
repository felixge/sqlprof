package main

import (
	"crypto/sha256"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sync"

	"github.com/felixge/sqlprof/db"
	"github.com/felixge/sqlprof/db/dbutil"
	"github.com/felixge/sqlprof/internal/profile"
	"github.com/sourcegraph/conc/pool"
)

func main() {
	os.Exit(sqlprof())
}

func sqlprof() int {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		return 1
	}
	return 0
}

func run() (err error) {
	// Parse the command line flags.
	var (
		cpuProfileF = flag.String("cpuprofile", "", "write cpu profile to file")
		traceF      = flag.String("trace", "", "write trace to file")
		memProfileF = flag.String("memprofile", "", "write memory profile to file")
		formatF     = flag.String("format", "table", "output format (table, csv)")
	)
	flag.Parse()

	// Start the CPU profile if requested.
	var stopCPUProfile func() error
	if stopCPUProfile, err = profile.StartCPUProfile(*cpuProfileF); err != nil {
		return fmt.Errorf("failed to start CPU profile: %w", err)
	}
	defer func() { err = errors.Join(err, stopCPUProfile()) }()

	// Start the trace if requested.
	var stopTrace func() error
	if stopTrace, err = profile.StartTrace(*traceF); err != nil {
		return fmt.Errorf("failed to start trace: %w", err)
	}
	defer func() { err = errors.Join(err, stopTrace()) }()

	// Start the memory profile if requested.
	stopMemProfile := profile.StartMemProfile(*memProfileF)
	defer func() { err = errors.Join(err, stopMemProfile()) }()

	// Execute the requested command.
	switch args := flag.Args(); len(args) {
	case 0:
		return fmt.Errorf("missing argument 1: must be the path to a profile")
	case 1:
		return runInteractive(flag.Arg(0))
	default:
		return runQuery(*formatF, args[0:len(args)-1], args[len(args)-1])
	}
}

func runInteractive(profilePath string) (err error) {
	// Load the profile into a temporary duckdb database.
	var db *db.DB
	if db, err = loadProfile(profilePath); err != nil {
		return fmt.Errorf("failed to load profile: %w", err)
		// Close the db. If we don't, we get a lock conflict when running the CLI.
	} else if err = db.Close(); err != nil {
		return fmt.Errorf("failed to close db: %w", err)
	}
	// Remove db file after the interactive session is done.
	defer func() { err = errors.Join(err, os.Remove(db.Path())) }()

	// Run the interactive duckdb CLI with the temporary database.
	cmd := exec.Command("duckdb", db.Path())
	cmd.Env = os.Environ()
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func runQuery(format string, paths []string, query string) (err error) {
	// Determine the row writer based on the requested format.
	var rowWriter *dbutil.RowWriter
	switch format {
	case "csv":
		rowWriter = dbutil.NewCSVWriter(os.Stdout)
	case "table":
		rowWriter = dbutil.NewASCIITableWriter(os.Stdout)
	default:
		return fmt.Errorf("unsupported format: %s", format)
	}
	defer rowWriter.Flush()

	// Execute the query against each profile using a pool of goroutines.
	var rowWriterMu sync.Mutex
	p := pool.New().WithErrors().WithMaxGoroutines(runtime.GOMAXPROCS(0))
	for _, path := range paths {
		p.Go(func() error {
			// Load the profile into a temporary duckdb database.
			var db *db.DB
			if db, err = loadProfile(path); err != nil {
				return fmt.Errorf("failed to load profile: %w", err)
			}
			// Close the db and remove its file after the interactive session is done.
			defer func() { err = errors.Join(err, db.Close(), os.Remove(db.Path())) }()

			// Execute the query against the database.
			rows, err := db.Query(query)
			if err != nil {
				return fmt.Errorf("failed to query: %w", err)
			}

			// Write the rows to the output.
			rowWriterMu.Lock()
			defer rowWriterMu.Unlock()
			return rowWriter.Rows(rows)
		})
	}
	return p.Wait()
}

func loadProfile(profilePath string) (*db.DB, error) {
	// Open the profile file.
	profileReader, err := os.Open(profilePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open profile: path=%q err=%w", profilePath, err)
	}

	// Determine the location for creating the temporary duckdb database.
	duckPath := duckTempPath(profilePath)
	// Remove any previous temporary database that might exist, the contents of
	// srcPath or the profile loading code could have changed.
	_ = os.Remove(duckPath)

	// Load the profile into the database.
	profile := db.Profile{
		Kind: db.ProfileKindTrace, // TODO: Support pprof profiles.
		Data: profileReader,
	}
	db, err := db.Create(duckPath, profile)
	if err != nil {
		return nil, fmt.Errorf("failed to create duckdb: path=%q err=%w", duckPath, err)
	}
	return db, nil
}

// duckTempPath returns a temporary path for a duckdb database file. The same
// path is returned for the same input path.
func duckTempPath(path string) string {
	dir := os.TempDir()
	name := fmt.Sprintf("sqlprof_%x.duckdb", sha256.Sum256([]byte(path)))
	return filepath.Join(dir, name)
}
