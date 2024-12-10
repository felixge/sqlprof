-- sample.sql --
select * from g_transitions order by end_time_ns asc limit 10;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+-----------+-------------+-----------------+----------+-------------------------------------------------------+--------------+--------------------------------------------------------------------------------------------------------------------+-------+------------+-------+
| g  |  from_state  | to_state |  reason   | duration_ns |   end_time_ns   | stack_id |                         stack                         | src_stack_id |                                                     src_stack                                                      | src_g |   src_m    | src_p |
+----+--------------+----------+-----------+-------------+-----------------+----------+-------------------------------------------------------+--------------+--------------------------------------------------------------------------------------------------------------------+-------+------------+-------+
|  1 | undetermined | running  | <nil>     |           0 | 965449946383232 | <nil>    | <nil>                                                 | <nil>        | <nil>                                                                                                              | <nil> | 8674447168 |     1 |
| 29 | notexist     | runnable | <nil>     |           0 | 965449946463744 |        5 | [runtime.traceStartReadCPU.func1]                     |            4 | [runtime.traceStartReadCPU runtime.StartTrace runtime/trace.Start main.generateTrace main.run main.main]           |     1 | 8674447168 |     1 |
| 30 | notexist     | runnable | <nil>     |           0 | 965449946466368 |        7 | [runtime.(*traceAdvancerState).start.func1]           |            6 | [runtime.(*traceAdvancerState).start runtime.StartTrace runtime/trace.Start main.generateTrace main.run main.main] |     1 | 8674447168 |     1 |
| 31 | notexist     | runnable | <nil>     |           0 | 965449946467904 |        9 | [runtime/trace.Start.func1]                           |            8 | [runtime/trace.Start main.generateTrace main.run main.main]                                                        |     1 | 8674447168 |     1 |
| 28 | undetermined | waiting  | <nil>     |           0 | 965449946470592 | <nil>    | <nil>                                                 | <nil>        | <nil>                                                                                                              | <nil> | 6098038784 |     0 |
| 28 | waiting      | runnable | <nil>     |         320 | 965449946470912 | <nil>    | <nil>                                                 | <nil>        | <nil>                                                                                                              | <nil> | 6098038784 |     0 |
| 28 | runnable     | running  | <nil>     |        3200 | 965449946474112 | <nil>    | <nil>                                                 | <nil>        | <nil>                                                                                                              | <nil> | 6098038784 |     0 |
|  1 | running      | runnable | preempted |      110784 | 965449946494016 |       10 | [main.runSleep main.generateTrace main.run main.main] | <nil>        | <nil>                                                                                                              |     1 | 8674447168 |     1 |
| 26 | undetermined | waiting  | <nil>     |           0 | 965449946531392 | <nil>    | <nil>                                                 | <nil>        | <nil>                                                                                                              | <nil> | 6099759104 |     2 |
| 26 | waiting      | runnable | <nil>     |         256 | 965449946531648 | <nil>    | <nil>                                                 | <nil>        | <nil>                                                                                                              | <nil> | 6099759104 |     2 |
+----+--------------+----------+-----------+-------------+-----------------+----------+-------------------------------------------------------+--------------+--------------------------------------------------------------------------------------------------------------------+-------+------------+-------+
-- block.sql --
select distinct on (from_state, reason) *
from g_transitions
where
    to_state = 'waiting'
order by end_time_ns
asc limit 10;
-- block.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+----------------------------+-------------+-----------------+----------+------------------------------------------------------------------------------------+--------------+-----------+-------+------------+-------+
| g  |  from_state  | to_state |           reason           | duration_ns |   end_time_ns   | stack_id |                                       stack                                        | src_stack_id | src_stack | src_g |   src_m    | src_p |
+----+--------------+----------+----------------------------+-------------+-----------------+----------+------------------------------------------------------------------------------------+--------------+-----------+-------+------------+-------+
| 28 | undetermined | waiting  | <nil>                      |           0 | 965449946470592 | <nil>    | <nil>                                                                              | <nil>        | <nil>     | <nil> | 6098038784 |     0 |
| 26 | running      | waiting  | sync                       |        6080 | 965449946541056 |       11 | [runtime.gcMarkDone runtime.gcBgMarkWorker]                                        | <nil>        | <nil>     |    26 | 6099759104 |     2 |
| 31 | running      | waiting  | system goroutine wait      |        1280 | 965449946638528 |       13 | [runtime/trace.Start.func1]                                                        | <nil>        | <nil>     |    31 | 8674447168 |     1 |
| 29 | running      | waiting  | chan receive               |        2304 | 965449946641536 |       14 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1] | <nil>        | <nil>     |    29 | 8674447168 |     1 |
| 17 | running      | waiting  | GC background sweeper wait |       24064 | 965449946961216 |       21 | [runtime.goparkunlock runtime.bgsweep]                                             | <nil>        | <nil>     |    17 | 6098038784 |     0 |
|  1 | running      | waiting  | sleep                      |      561408 | 965449947491072 |       24 | [time.Sleep main.runSleep main.generateTrace main.run main.main]                   | <nil>        | <nil>     |     1 | 6099759104 |     1 |
| 31 | waiting      | waiting  | <nil>                      |  1000542336 | 965450947180864 | <nil>    | <nil>                                                                              | <nil>        | <nil>     | <nil> | 6099185664 |     1 |
+----+--------------+----------+----------------------------+-------------+-----------------+----------+------------------------------------------------------------------------------------+--------------+-----------+-------+------------+-------+
-- unblock.sql --
select *
from g_transitions
where
    from_state = 'waiting' and
    src_g is not null and
    len(src_stack) > 1
order by end_time_ns
asc limit 10;
-- unblock.txt --
../testdata/testprog/go1.23.3.trace:
+----+------------+----------+--------+-------------+-----------------+----------+-------+--------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
| g  | from_state | to_state | reason | duration_ns |   end_time_ns   | stack_id | stack | src_stack_id |                                            src_stack                                             | src_g |   src_m    | src_p |
+----+------------+----------+--------+-------------+-----------------+----------+-------+--------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
| 26 | waiting    | runnable | <nil>  |      225856 | 965449946766912 | <nil>    | <nil> |           17 | [runtime.gcMarkDone runtime.gcBgMarkWorker]                                                      |    28 | 6098038784 |     0 |
| 17 | waiting    | runnable | <nil>  |         384 | 965449946769664 | <nil>    | <nil> |           18 | [runtime.systemstack_switch runtime.gcMarkTermination runtime.gcMarkDone runtime.gcBgMarkWorker] |    28 | 6098038784 |     0 |
| 27 | waiting    | runnable | <nil>  |      417152 | 965449946962560 | <nil>    | <nil> |           22 | [runtime.gcMarkDone runtime.gcBgMarkWorker]                                                      |    26 | 6098038784 |     0 |
|  1 | waiting    | runnable | <nil>  |    10959040 | 965459940049024 | <nil>    | <nil> |           59 | [runtime.chansend1 main.chanUnblock.func1]                                                       |    32 | 6098038784 |     1 |
+----+------------+----------+--------+-------------+-----------------+----------+-------+--------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
