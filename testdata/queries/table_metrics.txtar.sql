-- sample.sql --
select
    distinct on (name, src_stack_id is null, src_g is null, src_p is null, src_m is null) *
from metrics
order by name, src_stack_id, src_g, src_p, src_m;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+------------------+------------------------------------+---------+--------------+-------+-------+------------+
|   end_time_ns    |                name                |  value  | src_stack_id | src_g | src_p |   src_m    |
+------------------+------------------------------------+---------+--------------+-------+-------+------------+
| 1032001186971072 | /gc/heap/goal:bytes                | 4194304 | <nil>        |     1 |     1 | 8674447168 |
| 1032001806223232 | /memory/classes/heap/objects:bytes | 3811624 | <nil>        |     1 |     0 | 6138802176 |
| 1032005194811072 | /memory/classes/heap/objects:bytes | 4392856 | <nil>        | <nil> |     0 | 6139375616 |
| 1032001186969856 | /sched/gomaxprocs:threads          |      10 |            1 |     1 |     1 | 8674447168 |
+------------------+------------------------------------+---------+--------------+-------+-------+------------+
