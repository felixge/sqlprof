-- sample.sql --
select distinct on (from_state, to_state, reason) * from raw_g_transitions order by end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+----------------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
| g  |  from_state  | to_state |           reason           | duration_ns |   end_time_ns   | stack_id | src_stack_id | src_g |   src_m    | src_p |
+----+--------------+----------+----------------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
|  1 | undetermined | running  | <nil>                      |           0 | 965449946383232 | <nil>    | <nil>        | <nil> | 8674447168 |     1 |
| 29 | notexist     | runnable | <nil>                      |           0 | 965449946463744 |        5 |            4 |     1 | 8674447168 |     1 |
| 28 | undetermined | waiting  | <nil>                      |           0 | 965449946470592 | <nil>    | <nil>        | <nil> | 6098038784 |     0 |
| 28 | waiting      | runnable | <nil>                      |         320 | 965449946470912 | <nil>    | <nil>        | <nil> | 6098038784 |     0 |
| 28 | runnable     | running  | <nil>                      |        3200 | 965449946474112 | <nil>    | <nil>        | <nil> | 6098038784 |     0 |
|  1 | running      | runnable | preempted                  |      110784 | 965449946494016 |       10 | <nil>        |     1 | 8674447168 |     1 |
| 26 | running      | waiting  | sync                       |        6080 | 965449946541056 |       11 | <nil>        |    26 | 6099759104 |     2 |
| 27 | undetermined | runnable | <nil>                      |           0 | 965449946541760 | <nil>    | <nil>        | <nil> | 6099759104 |     2 |
| 31 | running      | syscall  | <nil>                      |        5761 | 965449946545793 |       12 | <nil>        |    31 | 8674447168 |     1 |
| 31 | syscall      | running  | <nil>                      |       91455 | 965449946637248 | <nil>    | <nil>        |    31 | 8674447168 |     1 |
| 31 | running      | waiting  | system goroutine wait      |        1280 | 965449946638528 |       13 | <nil>        |    31 | 8674447168 |     1 |
| 29 | running      | waiting  | chan receive               |        2304 | 965449946641536 |       14 | <nil>        |    29 | 8674447168 |     1 |
| 17 | running      | waiting  | GC background sweeper wait |       24064 | 965449946961216 |       21 | <nil>        |    17 | 6098038784 |     0 |
|  1 | running      | waiting  | sleep                      |      561408 | 965449947491072 |       24 | <nil>        |     1 | 6099759104 |     1 |
| 30 | running      | running  | <nil>                      |       86531 | 965450947014339 | <nil>    | <nil>        |    30 | 6099185664 |     1 |
| 31 | waiting      | waiting  | <nil>                      |  1000542336 | 965450947180864 | <nil>    | <nil>        | <nil> | 6099185664 |     1 |
| 31 | syscall      | syscall  | <nil>                      |       39750 | 965451948357958 | <nil>    | <nil>        |    31 | 6099759104 |     1 |
| 31 | runnable     | runnable | <nil>                      |       16645 | 965453950977669 | <nil>    | <nil>        | <nil> | 6099185664 |     2 |
| 32 | running      | notexist | <nil>                      |        1408 | 965459940049408 | <nil>    | <nil>        |    32 | 6098038784 |     1 |
+----+--------------+----------+----------------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
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
|                0 |       2001421440 |     187791246720 |  965449946383232 |  965459940060288 | 1769678339142708438 |
+------------------+------------------+------------------+------------------+------------------+---------------------+
-- reason.sql --
select distinct reason from raw_g_transitions order by 1;
-- reason.txt --
../testdata/testprog/go1.23.3.trace:
+----------------------------+
|           reason           |
+----------------------------+
| GC background sweeper wait |
| chan receive               |
| preempted                  |
| sleep                      |
| sync                       |
| system goroutine wait      |
| <nil>                      |
+----------------------------+
