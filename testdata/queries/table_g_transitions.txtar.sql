-- sample.sql --
select distinct on (from_state, to_state, reason, stack_id is null, src_stack_id is null, src_g is null, src_p is null, src_m is null) *
from g_transitions
order by from_state, to_state, reason, stack_id, src_stack_id, src_g, src_p, src_m, end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+----------------------------+-------------+------------------+----------+--------------+-------+------------+-------+
| g  |  from_state  | to_state |           reason           | duration_ns |   end_time_ns    | stack_id | src_stack_id | src_g |   src_m    | src_p |
+----+--------------+----------+----------------------------+-------------+------------------+----------+--------------+-------+------------+-------+
| 28 | notexist     | runnable | <nil>                      |           0 | 1032001187170624 |        5 |            4 |     1 | 8674447168 |     1 |
| 28 | runnable     | running  | <nil>                      |        2432 | 1032002093707328 | <nil>    | <nil>        | <nil> | 6138228736 |     0 |
|  7 | running      | notexist | <nil>                      |        1536 | 1032011186567488 | <nil>    | <nil>        |     7 | 8674447168 |     0 |
|  1 | running      | runnable | preempted                  |    14713024 | 1032003043970688 |       22 | <nil>        |     1 | 6138228736 |     0 |
|  1 | running      | running  | <nil>                      |     9309184 | 1032005194784704 | <nil>    | <nil>        |     1 | 8674447168 |     3 |
| 30 | running      | syscall  | <nil>                      |        3520 | 1032007197240384 |       14 | <nil>        |    30 | 6138228736 |     0 |
|  3 | running      | waiting  | GC background sweeper wait |       48448 | 1032001189297600 |       19 | <nil>        |     3 | 6138802176 |     2 |
| 28 | running      | waiting  | chan receive               |        3136 | 1032002093710464 |       11 | <nil>        |    28 | 6138228736 |     0 |
|  1 | running      | waiting  | sleep                      |    19993664 | 1032008318225408 |       10 | <nil>        |     1 | 6138228736 |     0 |
| 29 | running      | waiting  | sync                       |      165949 | 1032010201404608 |       38 | <nil>        |    29 | 6138228736 |     0 |
|  4 | running      | waiting  | system goroutine wait      |        1280 | 1032001189086848 |       12 | <nil>        |     4 | 6138802176 |     0 |
| 30 | syscall      | runnable | <nil>                      |       75520 | 1032001189183040 | <nil>    | <nil>        |    30 | 6138802176 | <nil> |
| 30 | syscall      | running  | <nil>                      |         128 | 1032007197275200 | <nil>    | <nil>        |    30 | 6138228736 |     0 |
| 30 | syscall      | syscall  | <nil>                      |       34688 | 1032007197275072 | <nil>    | <nil>        |    30 | 6138228736 |     0 |
|  4 | undetermined | runnable | <nil>                      |           0 | 1032001189085312 | <nil>    | <nil>        | <nil> | 6138802176 |     0 |
|  1 | undetermined | running  | <nil>                      |           0 | 1032001186955328 | <nil>    | <nil>        | <nil> | 8674447168 |     1 |
| 18 | undetermined | waiting  | <nil>                      |           0 | 1032002190272832 |       20 | <nil>        | <nil> | <nil>      | <nil> |
|  3 | undetermined | waiting  | <nil>                      |           0 | 1032001189122496 | <nil>    | <nil>        |    27 | 8674447168 |     1 |
| 17 | undetermined | waiting  | <nil>                      |           0 | 1032001286498048 | <nil>    | <nil>        | <nil> | 6139375616 |     1 |
|  3 | waiting      | runnable | <nil>                      |         448 | 1032001189122944 | <nil>    |           16 |    27 | 8674447168 |     1 |
| 28 | waiting      | runnable | <nil>                      |   101012608 | 1032002093704896 | <nil>    | <nil>        | <nil> | 6138228736 |     0 |
|  4 | waiting      | runnable | <nil>                      |      227648 | 1032001189314496 | <nil>    | <nil>        | <nil> | 6137655296 | <nil> |
| 18 | waiting      | waiting  | <nil>                      |  1001529280 | 1032003191802112 |       20 | <nil>        | <nil> | <nil>      | <nil> |
| 28 | waiting      | waiting  | <nil>                      |   101050496 | 1032005224147328 | <nil>    | <nil>        | <nil> | 6138228736 |     0 |
+----+--------------+----------+----------------------------+-------------+------------------+----------+--------------+-------+------------+-------+
-- block.sql --
select distinct on (from_state, reason)
    g, from_state, to_state, reason, funcs(stack_id), funcs(src_stack_id), src_g, src_m, src_p
from g_transitions
where
    to_state = 'waiting'
order by end_time_ns
asc limit 10;
-- block.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+----------------------------+------------------------------------------------------------------------------------+---------------------+-------+------------+-------+
| g  |  from_state  | to_state |           reason           |                                  funcs(stack_id)                                   | funcs(src_stack_id) | src_g |   src_m    | src_p |
+----+--------------+----------+----------------------------+------------------------------------------------------------------------------------+---------------------+-------+------------+-------+
|  1 | running      | waiting  | sleep                      | [time.Sleep main.runSleep main.run main.main]                                      | <nil>               |     1 | 8674447168 |     1 |
| 27 | undetermined | waiting  | <nil>                      | <nil>                                                                              | <nil>               | <nil> | 8674447168 |     1 |
| 28 | running      | waiting  | chan receive               | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1] | <nil>               |    28 | 6138802176 |     0 |
|  4 | running      | waiting  | system goroutine wait      | [runtime.(*scavengerState).park runtime.bgscavenge]                                | <nil>               |     4 | 6138802176 |     0 |
|  3 | running      | waiting  | GC background sweeper wait | [runtime.goparkunlock runtime.bgsweep]                                             | <nil>               |     3 | 6138802176 |     2 |
| 29 | running      | waiting  | sync                       | [runtime.traceAdvance runtime.(*traceAdvancerState).start.func1]                   | <nil>               |    29 | 6139375616 |     3 |
| 30 | waiting      | waiting  | <nil>                      | <nil>                                                                              | <nil>               | <nil> | 6139375616 |     3 |
+----+--------------+----------+----------------------------+------------------------------------------------------------------------------------+---------------------+-------+------------+-------+
-- unblock.sql --
select g, from_state, to_state, reason, funcs(stack_id), funcs(src_stack_id), src_g, src_m, src_p
from g_transitions
where
    from_state = 'waiting' and
    src_g is not null and
    len(funcs(src_stack_id)) > 1
order by end_time_ns
asc limit 10;
-- unblock.txt --
../testdata/testprog/go1.23.3.trace:
+---+------------+----------+--------+-----------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
| g | from_state | to_state | reason | funcs(stack_id) |                                       funcs(src_stack_id)                                        | src_g |   src_m    | src_p |
+---+------------+----------+--------+-----------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
| 3 | waiting    | runnable | <nil>  | <nil>           | [runtime.systemstack_switch runtime.gcMarkTermination runtime.gcMarkDone runtime.gcBgMarkWorker] |    27 | 8674447168 |     1 |
| 1 | waiting    | runnable | <nil>  | <nil>           | [runtime.chansend1 main.chanUnblock.func1]                                                       |     7 | 8674447168 |     0 |
+---+------------+----------+--------+-----------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
-- aggregate.sql --
select
    min(duration_ns),
    max(duration_ns),
    sum(duration_ns),
    min(end_time_ns),
    max(end_time_ns),
    sum(end_time_ns)
from g_transitions;
-- aggregate.txt --
../testdata/testprog/go1.23.3.trace:
+------------------+------------------+------------------+------------------+------------------+---------------------+
| min(duration_ns) | max(duration_ns) | sum(duration_ns) | min(end_time_ns) | max(end_time_ns) |  sum(end_time_ns)   |
+------------------+------------------+------------------+------------------+------------------+---------------------+
|                0 |       2002504256 |     185880664640 | 1032001186955328 | 1032011186595328 | 1868962724936891417 |
+------------------+------------------+------------------+------------------+------------------+---------------------+
