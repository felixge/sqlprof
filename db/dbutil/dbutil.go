package dbutil

import (
	"database/sql"
	"encoding/csv"
	"fmt"
	"io"

	"github.com/olekukonko/tablewriter"
)

func WriteCSV(w io.Writer, rows *sql.Rows) (err error) {
	result, err := newRowsResult(rows)
	if err != nil {
		return err
	}

	writer := csv.NewWriter(w)
	defer writer.Flush()

	// Write the header
	var header []string
	for _, column := range result.columns {
		header = append(header, column.name)
	}
	writer.Write(header)

	// Write the rows
	for _, row := range result.values {
		rowS := make([]string, len(row))
		for i, value := range row {
			rowS[i] = fmt.Sprintf("%v", value)
		}
		writer.Write(rowS)
	}
	return nil
}

func WriteASCIITable(w io.Writer, rows *sql.Rows) error {
	result, err := newRowsResult(rows)
	if err != nil {
		return err
	}

	table := tablewriter.NewWriter(w)
	// Set the table header
	var header []string
	for _, column := range result.columns {
		header = append(header, column.name)
	}
	table.SetHeader(header)
	table.SetAutoFormatHeaders(false)

	// Add the rows
	for _, row := range result.values {
		rowS := make([]string, len(row))
		for i, value := range row {
			rowS[i] = fmt.Sprintf("%v", value)
		}
		table.Append(rowS)
	}

	// Render the table
	table.Render()
	return nil
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
