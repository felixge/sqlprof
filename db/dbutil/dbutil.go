package dbutil

import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"io"
	"reflect"

	"github.com/olekukonko/tablewriter"
)

func NewCSVWriter(w io.Writer) *RowWriter {
	cw := csv.NewWriter(w)
	return &RowWriter{
		flush:       cw.Flush,
		writeRow:    cw.Write,
		writeHeader: cw.Write,
	}
}

func NewASCIITableWriter(w io.Writer) *RowWriter {
	tw := tablewriter.NewWriter(w)
	tw.SetAutoFormatHeaders(false)
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

type RowWriter struct {
	flush       func()
	writeHeader func([]string) error
	writeRow    func([]string) error
	columns     []column
}

func (c *RowWriter) Rows(rows *sql.Rows) error {
	// Fetch the rows
	result, err := newRowsResult(rows)
	if err != nil {
		return err
	}

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

func rowsWithSharedColumns(onHeader func([]string) error, onRow func([]any) error) func(*sql.Rows) error {
	var columns []column
	return func(rows *sql.Rows) error {
		result, err := newRowsResult(rows)
		if err != nil {
			return err
		}

		if columns == nil {
			var header []string
			for _, column := range result.columns {
				header = append(header, column.name)
			}
			columns = result.columns
			if err := onHeader(header); err != nil {
				return err
			}
		} else if !reflect.DeepEqual(columns, result.columns) {
			return fmt.Errorf("columns mismatch: got=%v != want=%v", result.columns, columns)
		}

		for _, row := range result.values {
			if err := onRow(row); err != nil {
				return err
			}
		}
		return nil
	}
}

type rowsResult struct {
	columns []column
	values  [][]any
}

type column struct {
	name string
	typ  string
}
