# sqlprof

sqlprof is a tool for exploring profiling data using duckdb SQL queries.

## Command Line Usage

The examples marked as TODO have not been implemented yet.

``` bash
# Explore a runtime trace in an interactive duckdb session
$ sqlprof go.trace

# Show the number of goroutines included in a runtime trace
$ sqlprof go.trace 'SELECT count(*) FROM goroutines'

# Convert a runtime trace into a permanent duckdb file (TODO)
$ sqlprof -o go.duckdb go.trace

# Run a query against a directory of runtime traces
$ sqlprof traces/*.trace 'SELECT * FROM g_transitions WHERE duration_ns > 50e6'
```

## Query Examples

### Compare Inlining

### Determine GC Overhead

## TODO

- [ ] Fix issues with leaf_func() and similar macros: https://github.com/duckdb/duckdb/issues/15296
- [ ] Traces
    - [ ] EventSync
    - [ ] EventLabel
    - [ ] EventStackSample
    - [ ] EventRangeBegin
    - [ ] EventRangeActive
    - [ ] EventRangeEnd
    - [ ] EventTaskBegin
    - [ ] EventTaskEnd
    - [ ] EventRegionBegin
    - [ ] EventRegionEnd
    - [ ] EventLog
    - [ ] EventExperimental
- [ ] pprof