# sqlprof

sqlprof is a tool for exploring profiling data using duckdb SQL queries.

## Examples

The examples marked as TODO have not been implemented yet.

``` bash
# Explore a runtime trace in an interactive duckdb session (TODO)
$ sqlprof go.trace

# Show the number of goroutines included in a runtime trace (TODO)
$ sqlprof go.trace 'SELECT count(*) FROM goroutines'

# Convert a runtime trace into a permanent duckdb file (TODO)
$ sqlprof -o go.duckdb go.trace

# Run a query against a directory of runtime traces (TODO)
$ sqlprof traces/*.trace 'SELECT * FROM g_events WHERE duration_ns > 50e6'
```

