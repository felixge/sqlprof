-- sample.sql --
select * from g_transitions order by end_time_ns asc limit 10;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+--------------+-------------+-----------------+----------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------+--------------------------------------------------------------------------------------------------------------------+
| g  |  from_state  | to_state |    reason    | duration_ns |   end_time_ns   | stack_id |                                                                       stack                                                                       | src_g |   src_m    | src_p | src_stack_id |                                                     src_stack                                                      |
+----+--------------+----------+--------------+-------------+-----------------+----------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------+--------------------------------------------------------------------------------------------------------------------+
|  1 | undetermined | running  | <nil>        |           0 | 956301026563968 | <nil>    | <nil>                                                                                                                                             | <nil> | 8674447168 |     2 | <nil>        | <nil>                                                                                                              |
| 33 | notexist     | runnable | <nil>        |           0 | 956301026671872 |        5 | [runtime.traceStartReadCPU.func1]                                                                                                                 |     1 | 8674447168 |     2 |            4 | [runtime.traceStartReadCPU runtime.StartTrace runtime/trace.Start main.generateTrace main.run main.main]           |
| 34 | notexist     | runnable | <nil>        |           0 | 956301026677376 |        7 | [runtime.(*traceAdvancerState).start.func1]                                                                                                       |     1 | 8674447168 |     2 |            6 | [runtime.(*traceAdvancerState).start runtime.StartTrace runtime/trace.Start main.generateTrace main.run main.main] |
| 33 | runnable     | running  | <nil>        |       11392 | 956301026683264 | <nil>    | <nil>                                                                                                                                             | <nil> | 6129643520 |     0 | <nil>        | <nil>                                                                                                              |
| 35 | notexist     | runnable | <nil>        |           0 | 956301026689344 |        9 | [runtime/trace.Start.func1]                                                                                                                       |     1 | 8674447168 |     2 |            8 | [runtime/trace.Start main.generateTrace main.run main.main]                                                        |
| 33 | running      | waiting  | chan receive |        6592 | 956301026689856 |       10 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1]                                                                |    33 | 6129643520 |     0 | <nil>        | <nil>                                                                                                              |
| 34 | runnable     | running  | <nil>        |       13376 | 956301026690752 | <nil>    | <nil>                                                                                                                                             | <nil> | 6129643520 |     0 | <nil>        | <nil>                                                                                                              |
| 34 | running      | waiting  | chan receive |        2560 | 956301026693312 |       11 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.(*traceAdvancerState).start.func1]                                                      |    34 | 6129643520 |     0 | <nil>        | <nil>                                                                                                              |
| 35 | runnable     | running  | <nil>        |       47744 | 956301026737088 | <nil>    | <nil>                                                                                                                                             | <nil> | 6129643520 |     0 | <nil>        | <nil>                                                                                                              |
| 35 | running      | syscall  | <nil>        |        4160 | 956301026741248 |       12 | [syscall.write syscall.Write internal/poll.ignoringEINTRIO internal/poll.(*FD).Write os.(*File).write os.(*File).Write runtime/trace.Start.func1] |    35 | 6129643520 |     0 | <nil>        | <nil>                                                                                                              |
+----+--------------+----------+--------------+-------------+-----------------+----------+---------------------------------------------------------------------------------------------------------------------------------------------------+-------+------------+-------+--------------+--------------------------------------------------------------------------------------------------------------------+
-- block.sql --
select distinct on (from_state, reason) *
from g_transitions
where
    to_state = 'waiting'
order by end_time_ns
asc limit 10;
-- block.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+-----------------------+-------------+-----------------+----------+------------------------------------------------------------------------------------+-------+------------+-------+--------------+-----------+
| g  |  from_state  | to_state |        reason         | duration_ns |   end_time_ns   | stack_id |                                       stack                                        | src_g |   src_m    | src_p | src_stack_id | src_stack |
+----+--------------+----------+-----------------------+-------------+-----------------+----------+------------------------------------------------------------------------------------+-------+------------+-------+--------------+-----------+
| 33 | running      | waiting  | chan receive          |        6592 | 956301026689856 |       10 | [runtime.chanrecv1 runtime.(*wakeableSleep).sleep runtime.traceStartReadCPU.func1] |    33 | 6129643520 |     0 | <nil>        | <nil>     |
| 35 | running      | waiting  | system goroutine wait |        1728 | 956301026823040 |       13 | [runtime/trace.Start.func1]                                                        |    35 | 6129643520 |     0 | <nil>        | <nil>     |
|  1 | running      | waiting  | sleep                 |     1151552 | 956301027715520 |       14 | [time.Sleep main.runSleep main.generateTrace main.run main.main]                   |     1 | 8674447168 |     2 | <nil>        | <nil>     |
|  2 | undetermined | waiting  | <nil>                 |           0 | 956302027914816 |       16 | [runtime.gopark runtime.goparkunlock runtime.forcegchelper]                        | <nil> | <nil>      | <nil> | <nil>        | <nil>     |
| 34 | running      | waiting  | sync                  |      194301 | 956302028109376 |       22 | [runtime.traceAdvance runtime.(*traceAdvancerState).start.func1]                   |    34 | 6130790400 |     1 | <nil>        | <nil>     |
| 35 | waiting      | waiting  | <nil>                 |  1001286592 | 956302028109632 | <nil>    | <nil>                                                                              | <nil> | 6130790400 |     1 | <nil>        | <nil>     |
+----+--------------+----------+-----------------------+-------------+-----------------+----------+------------------------------------------------------------------------------------+-------+------------+-------+--------------+-----------+
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
+---+------------+----------+--------+-------------+-----------------+----------+-------+-------+------------+-------+--------------+--------------------------------------------+
| g | from_state | to_state | reason | duration_ns |   end_time_ns   | stack_id | stack | src_g |   src_m    | src_p | src_stack_id |                 src_stack                  |
+---+------------+----------+--------+-------------+-----------------+----------+-------+-------+------------+-------+--------------+--------------------------------------------+
| 1 | waiting    | runnable | <nil>  |    10261376 | 956311025873856 | <nil>    | <nil> |    49 | 8674447168 |     3 |           29 | [runtime.chansend1 main.chanUnblock.func1] |
+---+------------+----------+--------+-------------+-----------------+----------+-------+-------+------------+-------+--------------+--------------------------------------------+
