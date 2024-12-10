-- sample.sql --
select
    distinct on (name, stack_id is null, g is null) *
from raw_metrics
order by end_time_ns;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------+------------------------------------+---------+----------+-------+---+------------+
|   end_time_ns   |                name                |  value  | stack_id |   g   | p |     m      |
+-----------------+------------------------------------+---------+----------+-------+---+------------+
| 965449946396096 | /sched/gomaxprocs:threads          |      10 |        1 |     1 | 1 | 8674447168 |
| 965449946397440 | /gc/heap/goal:bytes                | 4202496 | <nil>    |     1 | 1 | 8674447168 |
| 965449946428672 | /memory/classes/heap/objects:bytes | 4284416 | <nil>    |     1 | 1 | 8674447168 |
| 965449947494912 | /memory/classes/heap/objects:bytes | 3702896 | <nil>    | <nil> | 1 | 6099759104 |
+-----------------+------------------------------------+---------+----------+-------+---+------------+
