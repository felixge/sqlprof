# sqlprof

sqlprof is a power-user tool for exploring profiling data using duckdb SQL queries.
Currently it supports Go runtime traces and pprof files.

## Command Line Usage

``` bash
# Explore a pprof in an interactive duckdb session
$ sqlprof go.pprof

# Show the number of goroutines included in a runtime trace
$ sqlprof go.trace 'SELECT count(*) FROM goroutines'

# Convert a profile into a permanent duckdb
$ sqlprof -o go.duckdb go.trace

# Run a query against a directory of profiles
$ sqlprof traces/*.trace 'SELECT * FROM g_transitions WHERE duration_ns > 50e6'
```

## Query Examples

### Compare Inlining

Let's say you are trying to understand the impact [profile-guided optimization](https://go.dev/doc/pgo) has on the inlining decisions made by the Go compiler.

The commands below will give you the list of all functions that have been inlined at least once in the after.pprof profile, but were not inlined in the before.pprof profile:

```bash
# Write inline decisions for both profiles to CSV file
sqlprof -format=csv before.pprof 'select distinct name, inlined from frames join functions using (function_id)' > before.csv
sqlprof -format=csv after.pprof 'select distinct name, inlined from frames join functions using (function_id)' > after.csv
# Anlyze which functions got inlined
duckdb -c 'select name from (select * from ''after.csv'' except select * from ''before.csv'' b) where inlined order by 1'
```
```
        ┌─────────────────────────────────────────────┐
        │                    name                     │
        │                   varchar                   │
        ├─────────────────────────────────────────────┤
        │ bytes.(*Buffer).Write                       │
        │ bytes.(*Buffer).WriteByte                   │
        │ bytes.(*Buffer).WriteString                 │
        │ encoding/json.appendString[go.shape.string] │
        │ encoding/json.intEncoder                    │
        │ internal/abi.(*Type).IfaceIndir             │
        │ internal/runtime/atomic.(*Int64).Load       │
        │ internal/runtime/atomic.(*Uint32).Add       │
        │ internal/runtime/atomic.(*Uint32).Load      │
        │ internal/runtime/atomic.(*Uint8).Load       │
        │ reflect.Value.Elem                          │
        │ reflect.Value.Field                         │
        │ reflect.Value.Index                         │
        │ reflect.add                                 │
        │ runtime.(*mSpanStateBox).get                │
        │ runtime.(*mcentral).fullUnswept             │
        │ runtime.(*mheap).setSpans                   │
        │ runtime.(*mspan).countAlloc                 │
        │ runtime.(*mspan).typePointersOfUnchecked    │
        │ runtime.acquirem                            │
        │ runtime.addb                                │
        │ runtime.findObject                          │
        │ runtime.gcDrain                             │
        │ runtime.greyobject                          │
        │ runtime.mmap                                │
        │ runtime.readUintptr                         │
        │ runtime.spanOfUnchecked                     │
        │ runtime.typePointers.next                   │
        │ runtime.wbBufFlush1                         │
        │ strconv.formatBits                          │
        │ strconv.formatDigits                        │
        │ strconv.ryuDigits32                         │
        │ strconv.ryuFtoaShortest                     │
        │ sync.(*WaitGroup).Wait                      │
        ├─────────────────────────────────────────────┤
        │                   34 rows                   │
        └─────────────────────────────────────────────┘
```

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