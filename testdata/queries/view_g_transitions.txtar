-- sample.sql --
select * from g_transitions order by end_time_ns asc limit 10;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+---+--------------+----------+--------------+-------------+-------------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------------------------------------------------------------------------------------------------------------+
| g |  from_state  | to_state |    reason    | duration_ns | end_time_ns |                                                                       stack                                                                       | src_g |   src_m    | src_p |                                                     src_stack                                                      |
+---+--------------+----------+--------------+-------------+-------------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------------------------------------------------------------------------------------------------------------+
| 1 | undetermined | running  | <nil>        |           0 |         128 | <nil>                                                                                                                                             | <nil> | 8674447168 |     0 | <nil>                                                                                                              |
| 6 | notexist     | runnable | <nil>        |           0 |       15104 | [runtime.traceStartReadCPU.func1]                                                                                                                 |     1 | 8674447168 |     0 | [runtime.traceStartReadCPU runtime.StartTrace runtime/trace.Start main.generateTrace main.run main.main]           |
| 7 | notexist     | runnable | <nil>        |           0 |       15680 | [runtime.(*traceAdvancerState).start.func1]                                                                                                       |     1 | 8674447168 |     0 | [runtime.(*traceAdvancerState).start runtime.StartTrace runtime/trace.Start main.generateTrace main.run main.main] |
| 6 | runnable     | running  | <nil>        |        5632 |       20736 | <nil>                                                                                                                                             | <nil> | 6123270144 |     1 | <nil>                                                                                                              |
| 8 | notexist     | runnable | <nil>        |           0 |       33344 | [runtime/trace.Start.func1]                                                                                                                       |     1 | 8674447168 |     0 | [runtime/trace.Start main.generateTrace main.run main.main]                                                        |
| 7 | runnable     | running  | <nil>        |       33280 |       48960 | <nil>                                                                                                                                             | <nil> | 6124417024 |     2 | <nil>                                                                                                              |
| 7 | running      | waiting  | chan receive |       36800 |       85760 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.(*traceAdvancerState).start.func1]                                                      |     7 | 6124417024 |     2 | <nil>                                                                                                              |
| 6 | running      | waiting  | chan receive |       66560 |       87296 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1]                                                                |     6 | 6123270144 |     1 | <nil>                                                                                                              |
| 8 | runnable     | running  | <nil>        |       63168 |       96512 | <nil>                                                                                                                                             | <nil> | 6124417024 |     2 | <nil>                                                                                                              |
| 8 | running      | syscall  | <nil>        |        5376 |      101888 | [syscall.write syscall.Write internal/poll.ignoringEINTRIO internal/poll.(*FD).Write os.(*File).write os.(*File).Write runtime/trace.Start.func1] |     8 | 6124417024 |     2 | <nil>                                                                                                              |
+---+--------------+----------+--------------+-------------+-------------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------------------------------------------------------------------------------------------------------------+
-- block.sql --
select distinct on (reason) *
from g_transitions
where
    to_state = 'waiting'
order by end_time_ns
asc limit 10;
-- block.txt --
../testdata/testprog/go1.23.3.trace:
+---+--------------+----------+-----------------------+-------------+-------------+----------------------------------------------------------------------------------------------+-------+------------+-------+-------------------------------------------------------------+
| g |  from_state  | to_state |        reason         | duration_ns | end_time_ns |                                            stack                                             | src_g |   src_m    | src_p |                          src_stack                          |
+---+--------------+----------+-----------------------+-------------+-------------+----------------------------------------------------------------------------------------------+-------+------------+-------+-------------------------------------------------------------+
| 7 | running      | waiting  | chan receive          |       36800 |       85760 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.(*traceAdvancerState).start.func1] |     7 | 6124417024 |     2 | <nil>                                                       |
| 8 | running      | waiting  | system goroutine wait |         448 |      116672 | [runtime/trace.Start.func1]                                                                  |     8 | 6124417024 |     2 | <nil>                                                       |
| 1 | running      | waiting  | sleep                 |     1044416 |     1044544 | [time.Sleep main.runSleep main.generateTrace main.run main.main]                             |     1 | 8674447168 |     0 | <nil>                                                       |
| 2 | undetermined | waiting  | <nil>                 |           0 |  1000523136 | <nil>                                                                                        | <nil> | <nil>      | <nil> | [runtime.gopark runtime.goparkunlock runtime.forcegchelper] |
| 7 | running      | waiting  | sync                  |      184445 |  1000707840 | [runtime.traceAdvance runtime.(*traceAdvancerState).start.func1]                             |     7 | 8674447168 |     0 | <nil>                                                       |
+---+--------------+----------+-----------------------+-------------+-------------+----------------------------------------------------------------------------------------------+-------+------------+-------+-------------------------------------------------------------+
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
+---+------------+----------+--------+-------------+-------------+-------+-------+------------+-------+--------------------------------------------+
| g | from_state | to_state | reason | duration_ns | end_time_ns | stack | src_g |   src_m    | src_p |                 src_stack                  |
+---+------------+----------+--------+-------------+-------------+-------+-------+------------+-------+--------------------------------------------+
| 1 | waiting    | runnable | <nil>  |    10628416 | 10000319936 | <nil> |    17 | 6123270144 |     3 | [runtime.chansend1 main.chanUnblock.func1] |
+---+------------+----------+--------+-------------+-------------+-------+-------+------------+-------+--------------------------------------------+
