-- sample.sql --
select * from g_transitions order by end_time_ns asc limit 10;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+--------------+-------------+-----------------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------------------------------------------------------------------------------------------------------------+
| g  |  from_state  | to_state |    reason    | duration_ns |   end_time_ns   |                                                                       stack                                                                       | src_g |   src_m    | src_p |                                                     src_stack                                                      |
+----+--------------+----------+--------------+-------------+-----------------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------------------------------------------------------------------------------------------------------------+
|  1 | undetermined | running  | <nil>        |           0 | 956301026563968 | <nil>                                                                                                                                             | <nil> | 8674447168 |     2 | <nil>                                                                                                              |
| 33 | notexist     | runnable | <nil>        |           0 | 956301026671872 | [runtime.traceStartReadCPU.func1]                                                                                                                 |     1 | 8674447168 |     2 | [runtime.traceStartReadCPU runtime.StartTrace runtime/trace.Start main.generateTrace main.run main.main]           |
| 34 | notexist     | runnable | <nil>        |           0 | 956301026677376 | [runtime.(*traceAdvancerState).start.func1]                                                                                                       |     1 | 8674447168 |     2 | [runtime.(*traceAdvancerState).start runtime.StartTrace runtime/trace.Start main.generateTrace main.run main.main] |
| 33 | runnable     | running  | <nil>        |       11392 | 956301026683264 | <nil>                                                                                                                                             | <nil> | 6129643520 |     0 | <nil>                                                                                                              |
| 35 | notexist     | runnable | <nil>        |           0 | 956301026689344 | [runtime/trace.Start.func1]                                                                                                                       |     1 | 8674447168 |     2 | [runtime/trace.Start main.generateTrace main.run main.main]                                                        |
| 33 | running      | waiting  | chan receive |        6592 | 956301026689856 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1]                                                                |    33 | 6129643520 |     0 | <nil>                                                                                                              |
| 34 | runnable     | running  | <nil>        |       13376 | 956301026690752 | <nil>                                                                                                                                             | <nil> | 6129643520 |     0 | <nil>                                                                                                              |
| 34 | running      | waiting  | chan receive |        2560 | 956301026693312 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.(*traceAdvancerState).start.func1]                                                      |    34 | 6129643520 |     0 | <nil>                                                                                                              |
| 35 | runnable     | running  | <nil>        |       47744 | 956301026737088 | <nil>                                                                                                                                             | <nil> | 6129643520 |     0 | <nil>                                                                                                              |
| 35 | running      | syscall  | <nil>        |        4160 | 956301026741248 | [syscall.write syscall.Write internal/poll.ignoringEINTRIO internal/poll.(*FD).Write os.(*File).write os.(*File).Write runtime/trace.Start.func1] |    35 | 6129643520 |     0 | <nil>                                                                                                              |
+----+--------------+----------+--------------+-------------+-----------------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------------------------------------------------------------------------------------------------------------+
-- block.sql --
select distinct on (reason) *
from g_transitions
where
    to_state = 'waiting'
order by end_time_ns
asc limit 10;
-- block.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+-----------------------+-------------+-----------------+------------------------------------------------------------------------------------+-------+------------+-------+-----------+
| g  |  from_state  | to_state |        reason         | duration_ns |   end_time_ns   |                                       stack                                        | src_g |   src_m    | src_p | src_stack |
+----+--------------+----------+-----------------------+-------------+-----------------+------------------------------------------------------------------------------------+-------+------------+-------+-----------+
| 33 | running      | waiting  | chan receive          |        6592 | 956301026689856 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1] |    33 | 6129643520 |     0 | <nil>     |
| 35 | running      | waiting  | system goroutine wait |        1728 | 956301026823040 | [runtime/trace.Start.func1]                                                        |    35 | 6129643520 |     0 | <nil>     |
|  1 | running      | waiting  | sleep                 |     1151552 | 956301027715520 | [time.Sleep main.runSleep main.generateTrace main.run main.main]                   |     1 | 8674447168 |     2 | <nil>     |
|  2 | undetermined | waiting  | <nil>                 |           0 | 956302027914816 | [runtime.gopark runtime.goparkunlock runtime.forcegchelper]                        | <nil> | <nil>      | <nil> | <nil>     |
| 34 | running      | waiting  | sync                  |      194301 | 956302028109376 | [runtime.traceAdvance runtime.(*traceAdvancerState).start.func1]                   |    34 | 6130790400 |     1 | <nil>     |
+----+--------------+----------+-----------------------+-------------+-----------------+------------------------------------------------------------------------------------+-------+------------+-------+-----------+
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
| 1 | waiting    | runnable | <nil>  |    10261376 | 956311025873856 | <nil> |    49 | 8674447168 |     3 | [runtime.chansend1 main.chanUnblock.func1] |
+---+------------+----------+--------+-------------+-----------------+-------+-------+------------+-------+--------------------------------------------+
