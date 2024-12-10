-- sample.sql --
select distinct on (from_state, to_state, reason) * from raw_g_transitions order by end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+--------------+----------+----------------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
| g  |  from_state  | to_state |           reason           | duration_ns |   end_time_ns   | stack_id | src_stack_id | src_g |   src_m    | src_p |
+----+--------------+----------+----------------------------+-------------+-----------------+----------+--------------+-------+------------+-------+
|  1 | undetermined | running  | <nil>                      |           0 | 981359936358784 | <nil>    | <nil>        | <nil> | 6125793280 |     3 |
| 41 | undetermined | waiting  | <nil>                      |           0 | 981359936400064 | <nil>    | <nil>        | <nil> | 6124646400 |     0 |
| 41 | waiting      | runnable | <nil>                      |         256 | 981359936400320 | <nil>    | <nil>        | <nil> | 6124646400 |     0 |
| 41 | runnable     | running  | <nil>                      |        2368 | 981359936402688 | <nil>    | <nil>        | <nil> | 6124646400 |     0 |
| 49 | notexist     | runnable | <nil>                      |           0 | 981359936426240 |        5 |            4 |     1 | 6125793280 |     3 |
| 42 | running      | waiting  | system goroutine wait      |        4288 | 981359936440000 |       10 | <nil>        |    42 | 6126366720 |     1 |
| 43 | undetermined | runnable | <nil>                      |           0 | 981359936440512 | <nil>    | <nil>        | <nil> | 6126366720 |     1 |
| 49 | running      | waiting  | chan receive               |        1792 | 981359936443648 |       11 | <nil>        |    49 | 6126366720 |     1 |
| 51 | running      | syscall  | <nil>                      |        1920 | 981359936459648 |       13 | <nil>        |    51 | 6126366720 |     1 |
| 51 | syscall      | running  | <nil>                      |       32768 | 981359936492416 | <nil>    | <nil>        |    51 | 6126366720 |     1 |
|  1 | running      | runnable | preempted                  |      157824 | 981359936516608 |       15 | <nil>        |     1 | 6125793280 |     3 |
| 17 | running      | waiting  | GC background sweeper wait |        9856 | 981359936699904 |       19 | <nil>        |    17 | 6124646400 |     0 |
|  1 | running      | waiting  | sleep                      |      761088 | 981359937448448 |       21 | <nil>        |     1 | 6125793280 |     1 |
| 51 | syscall      | runnable | <nil>                      |       60736 | 981360937569984 | <nil>    | <nil>        |    51 | 6125219840 |     2 |
| 50 | running      | running  | <nil>                      |       69379 | 981360937632579 | <nil>    | <nil>        |    50 | 6124646400 |     1 |
| 50 | running      | waiting  | sync                       |      244669 | 981360937877248 |       37 | <nil>        |    50 | 6124646400 |     1 |
| 51 | waiting      | waiting  | <nil>                      |      306560 | 981360937877376 | <nil>    | <nil>        | <nil> | 6124646400 |     1 |
| 51 | syscall      | syscall  | <nil>                      |       74432 | 981361939089792 | <nil>    | <nil>        |    51 | 6126366720 |     0 |
| 51 | runnable     | runnable | <nil>                      |        7173 | 981363941564997 | <nil>    | <nil>        | <nil> | 6124646400 |     2 |
|  3 | running      | notexist | <nil>                      |         768 | 981369937455104 | <nil>    | <nil>        |     3 | 6125793280 |     0 |
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
|                0 |       2002647936 |     188913758976 |  981359936358784 |  981369937483328 | 1798841346108486097 |
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
