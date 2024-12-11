-- sample.sql --
select distinct on (from_state, to_state, reason, stack_id is null, src_stack_id is null, src_g is null, src_p is null, src_m is null) *
from g_transitions
order by from_state, to_state, reason, stack_id, src_stack_id, src_g, src_p, src_m, end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+----------------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
| g  |  from_state  | to_state |           reason           | duration_ns |   end_time_ns   | stack_id | src_stack_id | src_g |   src_m    | src_p |
+----+--------------+----------+----------------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
| 49 | notexist     | runnable | <nil>                      |           0 | 981359936426240 |        5 |            4 |     1 | 6125793280 |     3 |
| 51 | runnable     | runnable | <nil>                      |        7173 | 981363941564997 | <nil>    | <nil>        | <nil> | 6124646400 |     2 |
| 41 | runnable     | running  | <nil>                      |        2368 | 981359936402688 | <nil>    | <nil>        | <nil> | 6124646400 |     0 |
|  3 | running      | notexist | <nil>                      |         768 | 981369937455104 | <nil>    | <nil>        |     3 | 6125793280 |     0 |
|  1 | running      | runnable | preempted                  |    13285888 | 981361239038336 |       15 | <nil>        |     1 | 6124646400 |     0 |
|  1 | running      | running  | <nil>                      |     7088384 | 981363941669824 | <nil>    | <nil>        |     1 | 6125793280 |     1 |
| 51 | running      | syscall  | <nil>                      |         576 | 981368948169280 |       13 | <nil>        |    51 | 6124646400 |     0 |
| 17 | running      | waiting  | GC background sweeper wait |        9856 | 981359936699904 |       19 | <nil>        |    17 | 6124646400 |     0 |
| 49 | running      | waiting  | chan receive               |       18240 | 981360036583232 |       11 | <nil>        |    49 | 6124646400 |     0 |
|  1 | running      | waiting  | sleep                      |    22710016 | 981361261753664 |       21 | <nil>        |     1 | 6124646400 |     0 |
| 50 | running      | waiting  | sync                       |      154813 | 981368948166208 |       37 | <nil>        |    50 | 6124646400 |     0 |
| 41 | running      | waiting  | system goroutine wait      |      286848 | 981359936689536 |       10 | <nil>        |    41 | 6124646400 |     0 |
| 51 | syscall      | runnable | <nil>                      |       60736 | 981360937569984 | <nil>    | <nil>        |    51 | 6125219840 |     2 |
| 51 | syscall      | running  | <nil>                      |        7616 | 981368948176896 | <nil>    | <nil>        |    51 | 6124646400 |     0 |
| 51 | syscall      | syscall  | <nil>                      |       75397 | 981365944041797 | <nil>    | <nil>        |    51 | 6125793280 |     0 |
| 43 | undetermined | runnable | <nil>                      |           0 | 981359936440512 | <nil>    | <nil>        | <nil> | 6126366720 |     1 |
|  1 | undetermined | running  | <nil>                      |           0 | 981359936358784 | <nil>    | <nil>        | <nil> | 6125793280 |     3 |
| 34 | undetermined | waiting  | <nil>                      |           0 | 981360937632192 |       10 | <nil>        | <nil> | <nil>      | <nil> |
| 17 | undetermined | waiting  | <nil>                      |           0 | 981359936596288 | <nil>    | <nil>        |    41 | 6124646400 |     0 |
| 41 | undetermined | waiting  | <nil>                      |           0 | 981359936400064 | <nil>    | <nil>        | <nil> | 6124646400 |     0 |
| 18 | undetermined | waiting  | <nil>                      |           0 | 981359936714176 | <nil>    | <nil>        | <nil> | 6123499520 | <nil> |
| 17 | waiting      | runnable | <nil>                      |         576 | 981359936596864 | <nil>    |           17 |    41 | 6124646400 |     0 |
| 41 | waiting      | runnable | <nil>                      |         256 | 981359936400320 | <nil>    | <nil>        | <nil> | 6124646400 |     0 |
| 18 | waiting      | runnable | <nil>                      |         192 | 981359936714368 | <nil>    | <nil>        | <nil> | 6123499520 | <nil> |
| 34 | waiting      | waiting  | <nil>                      |  1001455232 | 981361939087424 |       10 | <nil>        | <nil> | <nil>      | <nil> |
| 33 | waiting      | waiting  | <nil>                      |   101010048 | 981362963206208 | <nil>    | <nil>        | <nil> | 6124646400 |     0 |
+----+--------------+----------+----------------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
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
| 41 | undetermined | waiting  | <nil>                      | <nil>                                                                              | <nil>               | <nil> | 6124646400 |     0 |
| 42 | running      | waiting  | system goroutine wait      | [runtime.gopark runtime.gcBgMarkWorker]                                            | <nil>               |    42 | 6126366720 |     1 |
| 49 | running      | waiting  | chan receive               | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1] | <nil>               |    49 | 6126366720 |     1 |
| 17 | running      | waiting  | GC background sweeper wait | [runtime.goparkunlock runtime.bgsweep]                                             | <nil>               |    17 | 6124646400 |     0 |
|  1 | running      | waiting  | sleep                      | [time.Sleep main.runSleep main.run main.main]                                      | <nil>               |     1 | 6125793280 |     1 |
| 50 | running      | waiting  | sync                       | [runtime.traceAdvance runtime.(*traceAdvancerState).start.func1]                   | <nil>               |    50 | 6124646400 |     1 |
| 51 | waiting      | waiting  | <nil>                      | <nil>                                                                              | <nil>               | <nil> | 6124646400 |     1 |
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
+----+------------+----------+--------+-----------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
| g  | from_state | to_state | reason | funcs(stack_id) |                                       funcs(src_stack_id)                                        | src_g |   src_m    | src_p |
+----+------------+----------+--------+-----------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
| 17 | waiting    | runnable | <nil>  | <nil>           | [runtime.systemstack_switch runtime.gcMarkTermination runtime.gcMarkDone runtime.gcBgMarkWorker] |    41 | 6124646400 |     0 |
|  1 | waiting    | runnable | <nil>  | <nil>           | [runtime.chansend1 main.chanUnblock.func1]                                                       |     3 | 6125793280 |     0 |
+----+------------+----------+--------+-----------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
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
|                0 |       2002647936 |     188913758976 |  981359936358784 |  981369937483328 | 1798841346108486097 |
+------------------+------------------+------------------+------------------+------------------+---------------------+
