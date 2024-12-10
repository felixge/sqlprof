-- sample.sql --
select * from raw_g_transitions order by end_time_ns asc limit 3;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+--------+-------------+-----------------+-------+------------+-------+----------+--------------+
| g  |  from_state  | to_state | reason | duration_ns |   end_time_ns   | src_g |   src_m    | src_p | stack_id | src_stack_id |
+----+--------------+----------+--------+-------------+-----------------+-------+------------+-------+----------+--------------+
|  1 | undetermined | running  | <nil>  |           0 | 956301026563968 | <nil> | 8674447168 |     2 | <nil>    | <nil>        |
| 33 | notexist     | runnable | <nil>  |           0 | 956301026671872 |     1 | 8674447168 |     2 |        5 |            4 |
| 34 | notexist     | runnable | <nil>  |           0 | 956301026677376 |     1 | 8674447168 |     2 |        7 |            6 |
+----+--------------+----------+--------+-------------+-----------------+-------+------------+-------+----------+--------------+
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
