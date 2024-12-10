-- sample.sql --
select * from g_transitions order by end_time_ns asc limit 10;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+---+--------------+----------+--------------+-------------+-----------------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------------------------------------------------------------------------------------------------------------+
| g |  from_state  | to_state |    reason    | duration_ns |   end_time_ns   |                                                                       stack                                                                       | src_g |   src_m    | src_p |                                                     src_stack                                                      |
+---+--------------+----------+--------------+-------------+-----------------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------------------------------------------------------------------------------------------------------------+
| 1 | undetermined | running  | <nil>        |           0 | 855758432930816 | <nil>                                                                                                                                             | <nil> | 8674447168 |     0 | <nil>                                                                                                              |
| 6 | notexist     | runnable | <nil>        |           0 | 855758432945792 | [runtime.traceStartReadCPU.func1]                                                                                                                 |     1 | 8674447168 |     0 | [runtime.traceStartReadCPU runtime.StartTrace runtime/trace.Start main.generateTrace main.run main.main]           |
| 7 | notexist     | runnable | <nil>        |           0 | 855758432946368 | [runtime.(*traceAdvancerState).start.func1]                                                                                                       |     1 | 8674447168 |     0 | [runtime.(*traceAdvancerState).start runtime.StartTrace runtime/trace.Start main.generateTrace main.run main.main] |
| 6 | runnable     | running  | <nil>        |        5632 | 855758432951424 | <nil>                                                                                                                                             | <nil> | 6123270144 |     1 | <nil>                                                                                                              |
| 8 | notexist     | runnable | <nil>        |           0 | 855758432964032 | [runtime/trace.Start.func1]                                                                                                                       |     1 | 8674447168 |     0 | [runtime/trace.Start main.generateTrace main.run main.main]                                                        |
| 7 | runnable     | running  | <nil>        |       33280 | 855758432979648 | <nil>                                                                                                                                             | <nil> | 6124417024 |     2 | <nil>                                                                                                              |
| 7 | running      | waiting  | chan receive |       36800 | 855758433016448 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.(*traceAdvancerState).start.func1]                                                      |     7 | 6124417024 |     2 | <nil>                                                                                                              |
| 6 | running      | waiting  | chan receive |       66560 | 855758433017984 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1]                                                                |     6 | 6123270144 |     1 | <nil>                                                                                                              |
| 8 | runnable     | running  | <nil>        |       63168 | 855758433027200 | <nil>                                                                                                                                             | <nil> | 6124417024 |     2 | <nil>                                                                                                              |
| 8 | running      | syscall  | <nil>        |        5376 | 855758433032576 | [syscall.write syscall.Write internal/poll.ignoringEINTRIO internal/poll.(*FD).Write os.(*File).write os.(*File).Write runtime/trace.Start.func1] |     8 | 6124417024 |     2 | <nil>                                                                                                              |
+---+--------------+----------+--------------+-------------+-----------------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------------------------------------------------------------------------------------------------------------+
-- block.sql --
select distinct on (reason) *
from g_transitions
where
    to_state = 'waiting'
order by end_time_ns
asc limit 10;
-- block.txt --
../testdata/testprog/go1.23.3.trace:
+---+--------------+----------+-----------------------+-------------+-----------------+----------------------------------------------------------------------------------------------+-------+------------+-------+-------------------------------------------------------------+
| g |  from_state  | to_state |        reason         | duration_ns |   end_time_ns   |                                            stack                                             | src_g |   src_m    | src_p |                          src_stack                          |
+---+--------------+----------+-----------------------+-------------+-----------------+----------------------------------------------------------------------------------------------+-------+------------+-------+-------------------------------------------------------------+
| 7 | running      | waiting  | chan receive          |       36800 | 855758433016448 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.(*traceAdvancerState).start.func1] |     7 | 6124417024 |     2 | <nil>                                                       |
| 8 | running      | waiting  | system goroutine wait |         448 | 855758433047360 | [runtime/trace.Start.func1]                                                                  |     8 | 6124417024 |     2 | <nil>                                                       |
| 1 | running      | waiting  | sleep                 |     1044416 | 855758433975232 | [time.Sleep main.runSleep main.generateTrace main.run main.main]                             |     1 | 8674447168 |     0 | <nil>                                                       |
| 2 | undetermined | waiting  | <nil>                 |           0 | 855759433453824 | <nil>                                                                                        | <nil> | <nil>      | <nil> | [runtime.gopark runtime.goparkunlock runtime.forcegchelper] |
| 7 | running      | waiting  | sync                  |      184445 | 855759433638528 | [runtime.traceAdvance runtime.(*traceAdvancerState).start.func1]                             |     7 | 8674447168 |     0 | <nil>                                                       |
+---+--------------+----------+-----------------------+-------------+-----------------+----------------------------------------------------------------------------------------------+-------+------------+-------+-------------------------------------------------------------+
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
+---+------------+----------+--------+-------------+-----------------+-------+-------+------------+-------+--------------------------------------------+
| g | from_state | to_state | reason | duration_ns |   end_time_ns   | stack | src_g |   src_m    | src_p |                 src_stack                  |
+---+------------+----------+--------+-------------+-----------------+-------+-------+------------+-------+--------------------------------------------+
| 1 | waiting    | runnable | <nil>  |    10628416 | 855768433250624 | <nil> |    17 | 6123270144 |     3 | [runtime.chansend1 main.chanUnblock.func1] |
+---+------------+----------+--------+-------------+-----------------+-------+-------+------------+-------+--------------------------------------------+
