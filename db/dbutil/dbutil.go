package dbutil

import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"io"
	"reflect"
	"sync"

	"github.com/olekukonko/tablewriter"
)

// NewCSVWriter creates a new RowWriter that writes CSV formatted rows.
func NewCSVWriter(w io.Writer) *RowWriter {
	cw := csv.NewWriter(w)
	return &RowWriter{
		flush:       cw.Flush,
		writeRow:    cw.Write,
		writeHeader: cw.Write,
	}
}

// NewASCIITableWriter creates a new RowWriter that writes ASCII table formatted rows.
func NewASCIITableWriter(w io.Writer) *RowWriter {
	tw := tablewriter.NewWriter(w)
	tw.SetAutoFormatHeaders(false)
	tw.SetAutoWrapText(false)
	writeHeader := func(header []string) error {
		tw.SetHeader(header)
		return nil
	}
	writeRow := func(row []string) error {
		tw.Append(row)
		return nil
	}
	return &RowWriter{
		flush:       tw.Render,
		writeRow:    writeRow,
		writeHeader: writeHeader,
	}
}

// RowWriter is a writer that writes rows to an underlying writer.
type RowWriter struct {
	mu          sync.Mutex
	flush       func()
	writeHeader func([]string) error
	writeRow    func([]string) error
	columns     []column
}

// Rows writes the rows from the sql.Rows to the underlying writer. It is safe
// to call this method concurrently.
func (c *RowWriter) Rows(rows *sql.Rows) error {
	// Fetch the rows
	result, err := newRowsResult(rows)
	if err != nil {
		return err
	}

	// Acquire a lock to prevent interleaving writes.
	c.mu.Lock()
	defer c.mu.Unlock()

	// Write the header and remember the columns or check if they match the
	// previous columns.
	if c.columns == nil {
		var header []string
		for _, column := range result.columns {
			header = append(header, column.name)
		}
		if err := c.writeHeader(header); err != nil {
			return err
		}
		c.columns = result.columns
	} else if !reflect.DeepEqual(c.columns, result.columns) {
		return fmt.Errorf("columns mismatch: got=%v != want=%v", result.columns, c.columns)
	}

	// Write the rows
	for _, row := range result.values {
		rowS := make([]string, len(row))
		for i, value := range row {
			rowS[i] = fmt.Sprintf("%v", value)
		}
		if err := c.writeRow(rowS); err != nil {
			return err
		}
	}
	return nil
}

// Flush flushes the underlying writer.
func (c *RowWriter) Flush() {
	c.flush()
}

func newRowsResult(rows *sql.Rows) (*rowsResult, error) {
	var result rowsResult
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
		result.columns = append(result.columns, column{
			name: columns[i],
			typ:  columnTypes[i].DatabaseTypeName(),
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
		result.values = append(result.values, values)
	}

	// Check for any errors encountered during iteration
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows iteration error: %w", err)
	}

	return &result, nil
}

// rowsResult holds the result of a rows query.
type rowsResult struct {
	columns []column
	values  [][]any
}

// column describes a column in a row.
type column struct {
	name string
	typ  string
}
