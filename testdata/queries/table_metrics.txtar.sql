-- sample.sql --
select
    distinct on (name, src_stack_id is null, src_g is null, src_p is null, src_m is null) *
from metrics
order by name, src_stack_id, src_g, src_p, src_m;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------+------------------------------------+---------+--------------+-------+-------+------------+
|   end_time_ns   |                name                |  value  | src_stack_id | src_g | src_p |   src_m    |
+-----------------+------------------------------------+---------+--------------+-------+-------+------------+
| 981359936363520 | /gc/heap/goal:bytes                | 4194304 | <nil>        |     1 |     3 | 6125793280 |
| 981369926458624 | /memory/classes/heap/objects:bytes | 4383416 | <nil>        |     1 |     0 | 6125219840 |
| 981361347321856 | /memory/classes/heap/objects:bytes | 3942024 | <nil>        | <nil> |     0 | 6124646400 |
| 981359936362624 | /sched/gomaxprocs:threads          |      10 |            1 |     1 |     3 | 6125793280 |
+-----------------+------------------------------------+---------+--------------+-------+-------+------------+
