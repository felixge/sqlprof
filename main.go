package main

import (
	"crypto/sha256"
	"database/sql"
	"encoding/csv"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"runtime/pprof"
	"runtime/trace"

	"github.com/felixge/sqlprof/db"
	"github.com/marcboeker/go-duckdb"
	"github.com/olekukonko/tablewriter"
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
	if stopCPUProfile, err = startCPUProfile(*cpuProfileF); err != nil {
		return fmt.Errorf("failed to start CPU profile: %w", err)
	}
	defer func() { err = errors.Join(err, stopCPUProfile()) }()

	// Start the trace if requested.
	var stopTrace func() error
	if stopTrace, err = startTrace(*traceF); err != nil {
		return fmt.Errorf("failed to start trace: %w", err)
	}
	defer func() { err = errors.Join(err, stopTrace()) }()

	// Start the memory profile if requested.
	stopMemProfile := startMemProfile(*memProfileF)
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
	var duckPath string
	if duckPath, err = loadProfile(profilePath); err != nil {
		return fmt.Errorf("failed to load profile: %w", err)
	}

	// Remove the duckdb file after the interactive session is done.
	defer func() { err = errors.Join(err, os.Remove(duckPath)) }()

	// Run the interactive duckdb CLI with the temporary database.
	cmd := exec.Command("duckdb", duckPath)
	cmd.Env = os.Environ()
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func runQuery(format string, paths []string, query string) (err error) {
	// TODO: Support multiple paths.
	if len(paths) > 1 {
		return fmt.Errorf("not implemented: multiple paths=%v query=%q", paths, query)
	}

	// Load the profile into a temporary duckdb database.
	var duckPath string
	if duckPath, err = loadProfile(paths[0]); err != nil {
		return fmt.Errorf("failed to load profile: %w", err)
	}

	// Remove the duckdb file after the interactive session is done.
	defer func() { err = errors.Join(err, os.Remove(duckPath)) }()

	// Connect to the duckdb database.
	var connector *duckdb.Connector
	if connector, err = duckdb.NewConnector(duckPath, nil); err != nil {
		return fmt.Errorf("failed to create duckdb connector: %w", err)
	}
	defer func() { err = errors.Join(err, connector.Close()) }()

	// Open the database connection.
	db := sql.OpenDB(connector)
	defer func() { err = errors.Join(err, db.Close()) }()

	// Execute the query.
	var result *queryResult
	if result, err = queryRows(db, query); err != nil {
		return fmt.Errorf("failed to execute query: %w", err)
	}

	// Print the query result based on the format.
	switch format {
	case "csv":
		printQueryResultCSV(result)
	case "table":
		printQueryResultTable(result)
	default:
		return fmt.Errorf("unsupported format: %s", format)
	}
	return nil
}

func loadProfile(profilePath string) (string, error) {
	// Open the profile file.
	profileReader, err := os.Open(profilePath)
	if err != nil {
		return "", fmt.Errorf("failed to open profile: path=%q err=%w", profilePath, err)
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
	if err := db.Create(duckPath, profile); err != nil {
		return "", fmt.Errorf("failed to create duckdb: path=%q err=%w", duckPath, err)
	}
	return duckPath, nil
}

// duckTempPath returns a temporary path for a duckdb database file. The same
// path is returned for the same input path.
func duckTempPath(path string) string {
	dir := os.TempDir()
	name := fmt.Sprintf("sqlprof_%x.duckdb", sha256.Sum256([]byte(path)))
	return filepath.Join(dir, name)
}

func startCPUProfile(path string) (stop func() error, err error) {
	// Default to a no-op stop function and return early if no path is provided.
	stop = func() error { return nil }
	if path == "" {
		return
	}

	// Create the file to write the profile to.
	var f *os.File
	if f, err = os.Create(path); err != nil {
		return
	}

	// Start the CPU profile or return the error and close the file.
	if err = pprof.StartCPUProfile(f); err != nil {
		return nil, errors.Join(err, f.Close())
	}

	// Return a function that stops the CPU profile and closes the file.
	stop = func() error {
		pprof.StopCPUProfile()
		return f.Close()
	}
	return
}

func startTrace(path string) (stop func() error, err error) {
	// Default to a no-op stop function and return early if no path is provided.
	stop = func() error { return nil }
	if path == "" {
		return
	}

	// Create the file to write the trace to.
	var f *os.File
	if f, err = os.Create(path); err != nil {
		return
	}

	// Start the trace or return the error and close the file.
	if err = trace.Start(f); err != nil {
		return nil, errors.Join(err, f.Close())
	}

	// Return a function that stops the trace and closes the file.
	stop = func() error {
		trace.Stop()
		return f.Close()
	}
	return
}

func startMemProfile(path string) func() error {
	return func() error {
		// Do nothing and return early if no path is provided.
		if path == "" {
			return nil
		}

		// Create the file to write the profile to.
		f, err := os.Create(path)
		if err != nil {
			return err
		}

		// Update the memory statistics and write the heap profile.
		runtime.GC()
		return errors.Join(pprof.WriteHeapProfile(f), f.Close())
	}
}

type queryResult struct {
	Columns []column
	Values  [][]any
}
type column struct {
	Name string
	Type string
}

func queryRows(db *sql.DB, query string, args ...interface{}) (*queryResult, error) {
	var result queryResult
	// Prepare the query statement
	rows, err := db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("query execution error: %w", err)
	}
	defer rows.Close()

	// Get column names
	columns, err := rows.Columns()
	if err != nil {
		return nil, fmt.Errorf("unable to get columns: %w", err)
	}

	// Get column types
	columnTypes, err := rows.ColumnTypes()
	if err != nil {
		return nil, fmt.Errorf("unable to get column types: %w", err)
	}

	// Create a slice to hold column descriptions
	for i := range columns {
		result.Columns = append(result.Columns, column{
			Name: columns[i],
			Type: columnTypes[i].DatabaseTypeName(),
		})
	}

	// Iterate through rows
	for rows.Next() {
		// Create a slice to hold column values
		values := make([]any, len(columns))
		valuePtrs := make([]any, len(columns))

		for i := range values {
			valuePtrs[i] = &values[i]
		}

		// Scan row into value pointers
		if err := rows.Scan(valuePtrs...); err != nil {
			return nil, fmt.Errorf("row scan error: %w", err)
		}

		// Append the row to the result
		result.Values = append(result.Values, values)
	}

	// Check for any errors encountered during iteration
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows iteration error: %w", err)
	}

	return &result, nil
}

func printQueryResultTable(result *queryResult) {
	table := tablewriter.NewWriter(os.Stdout)

	// Set the table header
	var header []string
	for _, column := range result.Columns {
		header = append(header, column.Name)
	}
	table.SetHeader(header)
	table.SetAutoFormatHeaders(false)

	// Add the rows
	for _, row := range result.Values {
		rowS := make([]string, len(row))
		for i, value := range row {
			rowS[i] = fmt.Sprintf("%v", value)
		}
		table.Append(rowS)
	}

	// Render the table
	table.Render()
}

func printQueryResultCSV(result *queryResult) {
	writer := csv.NewWriter(os.Stdout)
	defer writer.Flush()

	// Write the header
	var header []string
	for _, column := range result.Columns {
		header = append(header, column.Name)
	}
	writer.Write(header)

	// Write the rows
	for _, row := range result.Values {
		rowS := make([]string, len(row))
		for i, value := range row {
			rowS[i] = fmt.Sprintf("%v", value)
		}
		writer.Write(rowS)
	}
}
