-- sample.sql --
select distinct on (from_state, to_state, reason, stack_id is null, src_stack_id is null, src_g is null, src_p is null, src_m is null) *
from g_transitions
order by from_state, to_state, reason, stack_id, src_stack_id, src_g, src_p, src_m, end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+----------------------------+-------------+------------------+----------+--------------+-------+------------+-------+
| g  |  from_state  | to_state |           reason           | duration_ns |   end_time_ns    | stack_id | src_stack_id | src_g |   src_m    | src_p |
+----+--------------+----------+----------------------------+-------------+------------------+----------+--------------+-------+------------+-------+
| 28 | notexist     | runnable | <nil>                      |           0 | 1032652096955072 |        6 |            5 |     1 | 8674447168 |     1 |
| 27 | runnable     | running  | <nil>                      |        3264 | 1032652096969536 | <nil>    | <nil>        | <nil> | 6137360384 |     0 |
| 31 | running      | notexist | <nil>                      |         640 | 1032662102765888 | <nil>    | <nil>        |    31 | 6137933824 |     2 |
|  1 | running      | runnable | preempted                  |    12501376 | 1032652681749824 |       13 | <nil>        |     1 | 6137360384 |     0 |
|  1 | running      | running  | <nil>                      |     3193280 | 1032656102673088 | <nil>    | <nil>        |     1 | 6138507264 |     0 |
| 30 | running      | syscall  | <nil>                      |        3840 | 1032655101367872 |       14 | <nil>        |    30 | 6137360384 |     0 |
|  3 | running      | waiting  | GC background sweeper wait |       27520 | 1032652097597504 |       22 | <nil>        |     3 | 6137360384 |     0 |
| 28 | running      | waiting  | chan receive               |        3520 | 1032652097155456 |       12 | <nil>        |    28 | 6137360384 |     0 |
|  1 | running      | waiting  | sleep                      |    11508224 | 1032652693260224 |       24 | <nil>        |     1 | 6137360384 |     0 |
| 27 | running      | waiting  | sync                       |      181120 | 1032652097150656 |       11 | <nil>        |    27 | 6137360384 |     0 |
| 30 | running      | waiting  | system goroutine wait      |        1536 | 1032655101489280 |       15 | <nil>        |    30 | 6137360384 |     0 |
| 30 | syscall      | running  | <nil>                      |       59776 | 1032655101427648 | <nil>    | <nil>        |    30 | 6137360384 |     0 |
| 30 | syscall      | syscall  | <nil>                      |       31168 | 1032657103843264 | <nil>    | <nil>        |    30 | 6137360384 |     0 |
|  1 | undetermined | running  | <nil>                      |           0 | 1032652096885632 | <nil>    | <nil>        | <nil> | 8674447168 |     1 |
| 18 | undetermined | waiting  | <nil>                      |           0 | 1032653098506944 |       21 | <nil>        | <nil> | <nil>      | <nil> |
| 25 | undetermined | waiting  | <nil>                      |           0 | 1032652096919360 | <nil>    | <nil>        |     1 | 8674447168 |     1 |
| 27 | undetermined | waiting  | <nil>                      |           0 | 1032652096965888 | <nil>    | <nil>        | <nil> | 6137360384 |     0 |
|  4 | undetermined | waiting  | <nil>                      |           0 | 1032652097618752 | <nil>    | <nil>        | <nil> | 6136786944 | <nil> |
| 25 | waiting      | runnable | <nil>                      |         640 | 1032652096920000 | <nil>    |            4 |     1 | 8674447168 |     1 |
| 27 | waiting      | runnable | <nil>                      |         384 | 1032652096966272 | <nil>    | <nil>        | <nil> | 6137360384 |     0 |
|  4 | waiting      | runnable | <nil>                      |         192 | 1032652097618944 | <nil>    | <nil>        | <nil> | 6136786944 | <nil> |
| 18 | waiting      | waiting  | <nil>                      |  1001352640 | 1032654099859584 |       21 | <nil>        | <nil> | <nil>      | <nil> |
|  1 | waiting      | waiting  | <nil>                      |    44668864 | 1032654118457024 | <nil>    | <nil>        | <nil> | 6137360384 |     0 |
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
| 25 | undetermined | waiting  | <nil>                      | <nil>                                                                              | <nil>               |     1 | 8674447168 |     1 |
| 27 | running      | waiting  | sync                       | [runtime.gcMarkDone runtime.gcBgMarkWorker]                                        | <nil>               |    27 | 6137360384 |     0 |
| 28 | running      | waiting  | chan receive               | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1] | <nil>               |    28 | 6137360384 |     0 |
| 30 | running      | waiting  | system goroutine wait      | [runtime/trace.Start.func1]                                                        | <nil>               |    30 | 8674447168 |     1 |
|  3 | running      | waiting  | GC background sweeper wait | [runtime.goparkunlock runtime.bgsweep]                                             | <nil>               |     3 | 6137360384 |     0 |
|  1 | running      | waiting  | sleep                      | [time.Sleep main.runSleep main.run main.main]                                      | <nil>               |     1 | 6139080704 |     1 |
| 28 | waiting      | waiting  | <nil>                      | <nil>                                                                              | <nil>               | <nil> | 6137360384 |     1 |
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
+----+------------+----------+--------+-----------------+--------------------------------------------------------------------------------------------------------------------+-------+------------+-------+
| g  | from_state | to_state | reason | funcs(stack_id) |                                                funcs(src_stack_id)                                                 | src_g |   src_m    | src_p |
+----+------------+----------+--------+-----------------+--------------------------------------------------------------------------------------------------------------------+-------+------------+-------+
| 25 | waiting    | runnable | <nil>  | <nil>           | [runtime.StartTrace runtime/trace.Start github.com/felixge/sqlprof/internal/profile.StartTrace main.run main.main] |     1 | 8674447168 |     1 |
| 27 | waiting    | runnable | <nil>  | <nil>           | [runtime.gcMarkDone runtime.gcBgMarkWorker]                                                                        |    25 | 6137360384 |     0 |
|  3 | waiting    | runnable | <nil>  | <nil>           | [runtime.systemstack_switch runtime.gcMarkTermination runtime.gcMarkDone runtime.gcBgMarkWorker]                   |    25 | 6137360384 |     0 |
|  1 | waiting    | runnable | <nil>  | <nil>           | [runtime.chansend1 main.chanUnblock.func1]                                                                         |    31 | 6137933824 |     2 |
+----+------------+----------+--------+-----------------+--------------------------------------------------------------------------------------------------------------------+-------+------------+-------+
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
|                0 |       2002290560 |     187988686528 | 1032652096885632 | 1032662102806144 | 1882533356741042383 |
+------------------+------------------+------------------+------------------+------------------+---------------------+
