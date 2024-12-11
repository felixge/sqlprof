-- sample.sql --
select * from g_transitions order by end_time_ns asc limit 10;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+--------+-------------+-----------------+----------+---------------------------------------------+--------------+--------------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+
| g  |  from_state  | to_state | reason | duration_ns |   end_time_ns   | stack_id |                    funcs                    | src_stack_id |                                                                       src_funcs                                                                        | src_g |   src_m    | src_p |
+----+--------------+----------+--------+-------------+-----------------+----------+---------------------------------------------+--------------+--------------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+
|  1 | undetermined | running  | <nil>  |           0 | 981359936358784 | <nil>    | <nil>                                       | <nil>        | <nil>                                                                                                                                                  | <nil> | 6125793280 |     3 |
| 41 | undetermined | waiting  | <nil>  |           0 | 981359936400064 | <nil>    | <nil>                                       | <nil>        | <nil>                                                                                                                                                  | <nil> | 6124646400 |     0 |
| 41 | waiting      | runnable | <nil>  |         256 | 981359936400320 | <nil>    | <nil>                                       | <nil>        | <nil>                                                                                                                                                  | <nil> | 6124646400 |     0 |
| 41 | runnable     | running  | <nil>  |        2368 | 981359936402688 | <nil>    | <nil>                                       | <nil>        | <nil>                                                                                                                                                  | <nil> | 6124646400 |     0 |
| 49 | notexist     | runnable | <nil>  |           0 | 981359936426240 |        5 | [runtime.traceStartReadCPU.func1]           |            4 | [runtime.traceStartReadCPU runtime.StartTrace runtime/trace.Start github.com/felixge/sqlprof/internal/profile.StartTrace main.run main.main]           |     1 | 6125793280 |     3 |
| 50 | notexist     | runnable | <nil>  |           0 | 981359936427904 |        7 | [runtime.(*traceAdvancerState).start.func1] |            6 | [runtime.(*traceAdvancerState).start runtime.StartTrace runtime/trace.Start github.com/felixge/sqlprof/internal/profile.StartTrace main.run main.main] |     1 | 6125793280 |     3 |
| 51 | notexist     | runnable | <nil>  |           0 | 981359936428864 |        9 | [runtime/trace.Start.func1]                 |            8 | [runtime/trace.Start github.com/felixge/sqlprof/internal/profile.StartTrace main.run main.main]                                                        |     1 | 6125793280 |     3 |
| 42 | undetermined | waiting  | <nil>  |           0 | 981359936433280 | <nil>    | <nil>                                       | <nil>        | <nil>                                                                                                                                                  | <nil> | 6126366720 |     1 |
| 42 | waiting      | runnable | <nil>  |         192 | 981359936433472 | <nil>    | <nil>                                       | <nil>        | <nil>                                                                                                                                                  | <nil> | 6126366720 |     1 |
| 42 | runnable     | running  | <nil>  |        2240 | 981359936435712 | <nil>    | <nil>                                       | <nil>        | <nil>                                                                                                                                                  | <nil> | 6126366720 |     1 |
+----+--------------+----------+--------+-------------+-----------------+----------+---------------------------------------------+--------------+--------------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+
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
| g  |  from_state  | to_state |           reason           | duration_ns |   end_time_ns   | stack_id |                                       funcs                                        | src_stack_id | src_funcs | src_g |   src_m    | src_p |
+----+--------------+----------+----------------------------+-------------+-----------------+----------+------------------------------------------------------------------------------------+--------------+-----------+-------+------------+-------+
| 41 | undetermined | waiting  | <nil>                      |           0 | 981359936400064 | <nil>    | <nil>                                                                              | <nil>        | <nil>     | <nil> | 6124646400 |     0 |
| 42 | running      | waiting  | system goroutine wait      |        4288 | 981359936440000 |       10 | [runtime.gopark runtime.gcBgMarkWorker]                                            | <nil>        | <nil>     |    42 | 6126366720 |     1 |
| 49 | running      | waiting  | chan receive               |        1792 | 981359936443648 |       11 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1] | <nil>        | <nil>     |    49 | 6126366720 |     1 |
| 17 | running      | waiting  | GC background sweeper wait |        9856 | 981359936699904 |       19 | [runtime.goparkunlock runtime.bgsweep]                                             | <nil>        | <nil>     |    17 | 6124646400 |     0 |
|  1 | running      | waiting  | sleep                      |      761088 | 981359937448448 |       21 | [time.Sleep main.runSleep main.run main.main]                                      | <nil>        | <nil>     |     1 | 6125793280 |     1 |
| 50 | running      | waiting  | sync                       |      244669 | 981360937877248 |       37 | [runtime.traceAdvance runtime.(*traceAdvancerState).start.func1]                   | <nil>        | <nil>     |    50 | 6124646400 |     1 |
| 51 | waiting      | waiting  | <nil>                      |      306560 | 981360937877376 | <nil>    | <nil>                                                                              | <nil>        | <nil>     | <nil> | 6124646400 |     1 |
+----+--------------+----------+----------------------------+-------------+-----------------+----------+------------------------------------------------------------------------------------+--------------+-----------+-------+------------+-------+
-- unblock.sql --
select *
from g_transitions
where
    from_state = 'waiting' and
    src_g is not null and
    len(src_funcs) > 1
order by end_time_ns
asc limit 10;
-- unblock.txt --
../testdata/testprog/go1.23.3.trace:
+----+------------+----------+--------+-------------+-----------------+----------+-------+--------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
| g  | from_state | to_state | reason | duration_ns |   end_time_ns   | stack_id | funcs | src_stack_id |                                            src_funcs                                             | src_g |   src_m    | src_p |
+----+------------+----------+--------+-------------+-----------------+----------+-------+--------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
| 17 | waiting    | runnable | <nil>  |         576 | 981359936596864 | <nil>    | <nil> |           17 | [runtime.systemstack_switch runtime.gcMarkTermination runtime.gcMarkDone runtime.gcBgMarkWorker] |    41 | 6124646400 |     0 |
|  1 | waiting    | runnable | <nil>  |    10979456 | 981369937454976 | <nil>    | <nil> |           60 | [runtime.chansend1 main.chanUnblock.func1]                                                       |     3 | 6125793280 |     0 |
+----+------------+----------+--------+-------------+-----------------+----------+-------+--------------+--------------------------------------------------------------------------------------------------+-------+------------+-------+
