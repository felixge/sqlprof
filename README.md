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

The first step is to extract the inlining information from a before and after pprof into CSV files as shown below:

```bash
sqlprof -format=csv before.pprof \
    'select distinct name, inlined from frames join functions using (function_id)' > before.csv
sqlprof -format=csv after.pprof \
    'select distinct name, inlined from frames join functions using (function_id)' > after.csv
```

Then we can run a standalone `duckdb` session and run the following query to determine which functions were inlined due to pgo:

```sql
select name
from (
    select * from 'after.csv'
    except
    select * from 'before.csv'
) where inlined
order by 1
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

The query below will show the percentage of CPU samples that are spent in various GC-related functions, as well as the cumulative percentage.

```sql
create temporary macro gc_category(_funcs) as (
    case
        when list_contains(_funcs, 'runtime.gcBgMarkWorker') then 'background gc'
        when list_contains(_funcs, 'runtime.gcAssistAlloc') then 'gc assist'
        when list_contains(_funcs, 'gcWriteBarrier') then 'write barrier'
        when list_contains(_funcs, 'runtime.bgsweep') then 'background sweep'
    end
);

with cpu_samples as (
    select funcs(src_stack_id) as funcs, value
    from stack_samples
    where type = 'samples/count'
)

select 
    gc_category(funcs) as gc_category,
    round(sum(value) / (select sum(value) from cpu_samples) * 100, 2) as percent
from cpu_samples
where gc_category is not null
group by grouping sets ((gc_category), ())
order by 2 desc;
```

```
┌──────────────────┬─────────┐
│   gc_category    │ percent │
│     varchar      │ double  │
├──────────────────┼─────────┤
│                  │   10.51 │
│ background gc    │    6.56 │
│ write barrier    │    1.98 │
│ gc assist        │    1.53 │
│ background sweep │    0.45 │
└──────────────────┴─────────┘
```

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