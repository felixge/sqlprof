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
| 1032652096893504 | /gc/heap/goal:bytes                | 4194304 | <nil>        |     1 |     1 | 8674447168 |
| 1032652622188928 | /memory/classes/heap/objects:bytes | 3816736 | <nil>        |     1 |     0 | 6139080704 |
| 1032652098010368 | /memory/classes/heap/objects:bytes | 3704680 | <nil>        | <nil> |     1 | 6139080704 |
| 1032652096892160 | /sched/gomaxprocs:threads          |      10 |            1 |     1 |     1 | 8674447168 |
+------------------+------------------------------------+---------+--------------+-------+-------+------------+
