package dbutil

import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"io"
	"reflect"

	"github.com/olekukonko/tablewriter"
)

func NewCSVWriter(w io.Writer) *CSVWriter {
	return &CSVWriter{
		w: csv.NewWriter(w),
	}
}

type CSVWriter struct {
	w       *csv.Writer
	columns []column
}

func (c *CSVWriter) Rows(rows *sql.Rows) error {
	result, err := newRowsResult(rows)
	if err != nil {
		return err
	}

	if c.columns == nil {
		// Write the header and remember the columns
		var header []string
		for _, column := range result.columns {
			header = append(header, column.name)
		}
		c.w.Write(header)
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
		c.w.Write(rowS)
	}

	return nil
}

func (c *CSVWriter) Flush() {
	c.w.Flush()
}

func NewASCIITableWriter(w io.Writer) *ASCIITableWriter {
	return &ASCIITableWriter{
		w: tablewriter.NewWriter(w),
	}
}

type ASCIITableWriter struct {
	w       *tablewriter.Table
	columns []column
}

func (a *ASCIITableWriter) Rows(rows *sql.Rows) error {
	result, err := newRowsResult(rows)
	if err != nil {
		return err
	}

	if a.columns == nil {
		// Set the table header and remember the columns
		var header []string
		for _, column := range result.columns {
			header = append(header, column.name)
		}
		a.w.SetHeader(header)
		a.w.SetAutoFormatHeaders(false)
		a.columns = result.columns
	} else if !reflect.DeepEqual(a.columns, result.columns) {
		return fmt.Errorf("columns mismatch: got=%v != want=%v", result.columns, a.columns)
	}

	// Add the rows
	for _, row := range result.values {
		rowS := make([]string, len(row))
		for i, value := range row {
			rowS[i] = fmt.Sprintf("%v", value)
		}
		a.w.Append(rowS)
	}

	return nil
}

func (a *ASCIITableWriter) Flush() {
	a.w.Render()
}

type rowsResult struct {
	columns []column
	values  [][]any
}

type column struct {
	name string
	typ  string
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
