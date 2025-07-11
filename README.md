# sqlprof

sqlprof is a power-user tool for exploring profiling data using duckdb SQL queries.
Currently it supports Go runtime traces and pprof files.

⚠️ This project is still in early stages of development. The names of tables, columns and functions are subject to change.

## Installation

```
go install github.com/felixge/sqlprof@latest
```

## Command Line Usage

``` bash
# Explore a pprof in an interactive duckdb session
sqlprof go.pprof

# Show the number of goroutines included in a runtime trace
sqlprof go.trace 'SELECT count(*) FROM goroutines'

# Convert a profile into a permanent duckdb
sqlprof -o go.duckdb go.trace

# Run a query against a directory of profiles
sqlprof traces/*.trace 'SELECT * FROM g_transitions WHERE duration_ns > 50e6'
```

## Documentation

There is currently no dedicated documentation for sqlprof. But here are some pointers:

* Use the `.tables` command in duckdb to list all tables and views.
* Look at the [db/schema.sql](./db/schema.sql) for more details on the schema.

## Use Case Examples

### Off-CPU Histograms

Let's say you want to analyze the distribution of durations that goroutines spend Off-CPU via a specific stack trace.

Below is an example of doing this for `time.Sleep` calls:

```
sqlprof ./testdata/testprog/go1.23.3.trace
```
```sql
with sleeps as (
    select *
    from g_transitions
    where list_contains(stack(stack_id), 'time.Sleep')
)

select * from histogram(sleeps, duration_ns);
```
```
┌──────────────────────────┬────────┬──────────────────────────────────────────────────────────────────────────────────┐
│           bin            │ count  │                                       bar                                        │
│         varchar          │ uint64 │                                     varchar                                      │
├──────────────────────────┼────────┼──────────────────────────────────────────────────────────────────────────────────┤
│ x <= 2000000             │    107 │ ████████████████████████████████████████████████████████████████████████████████ │
│ 2000000 < x <= 4000000   │     13 │ █████████▋                                                                       │
│ 4000000 < x <= 6000000   │     12 │ ████████▉                                                                        │
│ 6000000 < x <= 8000000   │     15 │ ███████████▏                                                                     │
│ 8000000 < x <= 10000000  │      7 │ █████▏                                                                           │
│ 10000000 < x <= 12000000 │     12 │ ████████▉                                                                        │
│ 12000000 < x <= 14000000 │      5 │ ███▋                                                                             │
│ 14000000 < x <= 16000000 │      6 │ ████▍                                                                            │
│ 16000000 < x <= 18000000 │      5 │ ███▋                                                                             │
│ 18000000 < x <= 20000000 │      3 │ ██▏                                                                              │
│ 20000000 < x <= 22000000 │      9 │ ██████▋                                                                          │
│ 22000000 < x <= 24000000 │      3 │ ██▏                                                                              │
│ 24000000 < x <= 26000000 │      2 │ █▍                                                                               │
├──────────────────────────┴────────┴──────────────────────────────────────────────────────────────────────────────────┤
│ 13 rows                                                                                                    3 columns │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

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
select name from 'after.csv' where inlined
except
select name from 'before.csv' where inlined
order by 1;
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

### Categorize Stack Traces

Go's official GC guide [recommends](https://golang.org/doc/gc-guide#Identiying_costs) to identify GC costs by analyzing stack traces in CPU profiles.

Below is an example of using sqlprof to categorize memory management related stack traces of a CPU profile produced by a JSON decoding benchmark:

```
sqlprof ./testdata/gcoverhead/go1.23.3.pprof
```
```sql
create or replace temporary macro stack_category(_funcs) as (
    case
        when list_contains(_funcs, 'runtime.gcBgMarkWorker') then 'background gc'
        when list_contains(_funcs, 'runtime.bgsweep') then 'background sweep'
        when list_contains(_funcs, 'gcWriteBarrier') then 'write barrier'
        when list_contains(_funcs, 'runtime.gcAssistAlloc') then 'gc assist'
        when list_contains(_funcs, 'runtime.mallocgc') then 'allocation'
    end
);

with cpu_samples as (
    select funcs(src_stack_id) as funcs, value
    from stack_samples
    where type = 'cpu/nanoseconds'
)

select 
    stack_category(funcs) as stack_category,
    round(sum(value) / 1e9, 1) cpu_s,
    round(sum(value) / (select sum(value) from cpu_samples) * 100, 2) as percent
from cpu_samples
where stack_category(funcs) is not null
group by grouping sets ((stack_category), ())
order by 2 desc;
```

```
┌──────────────────┬────────┬─────────┐
│  stack_category  │ cpu_s  │ percent │
│     varchar      │ double │ double  │
├──────────────────┼────────┼─────────┤
│                  │    2.4 │   37.36 │
│ allocation       │    1.6 │   24.81 │
│ write barrier    │    0.6 │    8.68 │
│ background sweep │    0.1 │    1.86 │
│ background gc    │    0.1 │    1.71 │
│ gc assist        │    0.0 │    0.31 │
└──────────────────┴────────┴─────────┘
```

### Identify Spikes in Runnable Goroutines

Spikes in runnable goroutines can cause increased scheduling latency. The
following query tracks the runnable goroutines over time (in 1ms buckets
starting at the beginning of the provided execution trace).

```
sqlprof /path/to/trace.bin
```
```sql
select
    bucket,
    enterrunnable,
    leaverunnable,
    enterrunnable - leaverunnable as delta,
    sum(enterrunnable - leaverunnable) over (order by bucket) as runnable_count
  from (
    select
      (end_time_ns - (select min(end_time_ns) from g_transitions)) // 1_000_000 as bucket,
      count(*) filter (where to_state = 'runnable') as enterrunnable,
      count(*) filter (where from_state = 'runnable') as leaverunnable
    from g_transitions
    where from_state = 'runnable' or to_state = 'runnable'
    group by bucket
  )
  order by runnable_count desc;
```

The output below indicates that the runnable goroutine count peaks at 577ms into
the execution trace, with a count of over 5000 runnable goroutines at that time.

```
┌────────┬───────────────┬───────────────┬───────┬────────────────┐
│ bucket │ enterrunnable │ leaverunnable │ delta │ runnable_count │
│ int64  │     int64     │     int64     │ int64 │     int128     │
├────────┼───────────────┼───────────────┼───────┼────────────────┤
│    577 │           251 │           187 │    64 │           5118 │
│    576 │           335 │           151 │   184 │           5054 │
│    669 │           350 │           134 │   216 │           5015 │
│     ·  │             · │             · │     · │              · │
│     ·  │             · │             · │     · │              · │
│     ·  │             · │             · │     · │              · │
│    436 │           103 │           104 │    -1 │              0 │
│    454 │            74 │            74 │     0 │              0 │
│    461 │            57 │            58 │    -1 │              0 │
│   1005 │           172 │           174 │    -2 │              0 │
├────────┴───────────────┴───────────────┴───────┴────────────────┤
```

## Custom Meta Data

To load custom meta data, create a JSON file with the same name as the profile, adding a `.json` extension. For example, for `go.trace`, create `go.trace.json` in the same directory. Call the `meta_json()` function to access the data.

TODO: Map reduce example.

## TODO

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
    - [ ] meta columns
    - [ ] pivot?