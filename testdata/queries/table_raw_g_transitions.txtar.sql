-- sample.sql --
select distinct on (from_state, to_state, reason) * from raw_g_transitions order by end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+-----------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
| g  |  from_state  | to_state |        reason         | duration_ns |   end_time_ns   | stack_id | src_stack_id | src_g |   src_m    | src_p |
+----+--------------+----------+-----------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
|  1 | undetermined | running  | <nil>                 |           0 | 956301026563968 | <nil>    | <nil>        | <nil> | 8674447168 |     2 |
| 33 | notexist     | runnable | <nil>                 |           0 | 956301026671872 |        5 |            4 |     1 | 8674447168 |     2 |
| 33 | runnable     | running  | <nil>                 |       11392 | 956301026683264 | <nil>    | <nil>        | <nil> | 6129643520 |     0 |
| 33 | running      | waiting  | chan receive          |        6592 | 956301026689856 |       10 | <nil>        |    33 | 6129643520 |     0 |
| 35 | running      | syscall  | <nil>                 |        4160 | 956301026741248 |       12 | <nil>        |    35 | 6129643520 |     0 |
| 35 | syscall      | running  | <nil>                 |       80064 | 956301026821312 | <nil>    | <nil>        |    35 | 6129643520 |     0 |
| 35 | running      | waiting  | system goroutine wait |        1728 | 956301026823040 |       13 | <nil>        |    35 | 6129643520 |     0 |
|  1 | running      | waiting  | sleep                 |     1151552 | 956301027715520 |       14 | <nil>        |     1 | 8674447168 |     2 |
|  1 | waiting      | runnable | <nil>                 |     1278720 | 956301028994240 | <nil>    | <nil>        | <nil> | 6129643520 |     2 |
|  1 | running      | runnable | preempted             |     2272832 | 956301060719744 |       15 | <nil>        |     1 | 6129643520 |     2 |
|  2 | undetermined | waiting  | <nil>                 |           0 | 956302027914816 |       16 | <nil>        | <nil> | <nil>      | <nil> |
| 34 | running      | running  | <nil>                 |      177795 | 956302027915075 | <nil>    | <nil>        |    34 | 6130790400 |     1 |
| 34 | running      | waiting  | sync                  |      194301 | 956302028109376 |       22 | <nil>        |    34 | 6130790400 |     1 |
| 35 | waiting      | waiting  | <nil>                 |  1001286592 | 956302028109632 | <nil>    | <nil>        | <nil> | 6130790400 |     1 |
| 35 | syscall      | syscall  | <nil>                 |       66880 | 956304030590208 | <nil>    | <nil>        |    35 | 6130790400 |     0 |
| 49 | running      | notexist | <nil>                 |        1216 | 956311025874496 | <nil>    | <nil>        |    49 | 8674447168 |     3 |
+----+--------------+----------+-----------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
-- aggregate.sql --
select
    min(duration_ns),
    max(duration_ns),
    sum(duration_ns),
    min(end_time_ns),
    max(end_time_ns),
    sum(end_time_ns)
from raw_g_transitions;
-- aggregate.txt --
../testdata/testprog/go1.23.3.trace:
+------------------+------------------+------------------+------------------+------------------+---------------------+
| min(duration_ns) | max(duration_ns) | sum(duration_ns) | min(end_time_ns) | max(end_time_ns) |  sum(end_time_ns)   |
+------------------+------------------+------------------+------------------+------------------+---------------------+
|                0 |       1001430528 |      84006790016 |  956301026563968 |  956311025903360 | 1308226173165436273 |
+------------------+------------------+------------------+------------------+------------------+---------------------+
-- reason.sql --
select distinct reason from raw_g_transitions order by 1;
-- reason.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------------+
|        reason         |
+-----------------------+
| chan receive          |
| preempted             |
| sleep                 |
| sync                  |
| system goroutine wait |
| <nil>                 |
+-----------------------+
