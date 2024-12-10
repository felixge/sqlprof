-- sample.sql --
select * from raw_g_transitions order by end_time_ns asc limit 3;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+---+--------------+----------+--------+-------------+-------------+-------+------------+-------+----------+--------------+
| g |  from_state  | to_state | reason | duration_ns | end_time_ns | src_g |   src_m    | src_p | stack_id | src_stack_id |
+---+--------------+----------+--------+-------------+-------------+-------+------------+-------+----------+--------------+
| 1 | undetermined | running  | <nil>  |           0 |         128 | <nil> | 8674447168 |     0 | <nil>    | <nil>        |
| 6 | notexist     | runnable | <nil>  |           0 |       15104 |     1 | 8674447168 |     0 |        5 |            4 |
| 7 | notexist     | runnable | <nil>  |           0 |       15680 |     1 | 8674447168 |     0 |        7 |            6 |
+---+--------------+----------+--------+-------------+-------------+-------+------------+-------+----------+--------------+
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
+------------------+------------------+------------------+------------------+------------------+------------------+
| min(duration_ns) | max(duration_ns) | sum(duration_ns) | min(end_time_ns) | max(end_time_ns) | sum(end_time_ns) |
+------------------+------------------+------------------+------------------+------------------+------------------+
|                0 |       1008225344 |      74038089664 |              128 |      10000332864 |    6472465391160 |
+------------------+------------------+------------------+------------------+------------------+------------------+
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
