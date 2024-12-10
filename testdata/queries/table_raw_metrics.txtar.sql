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
| 981359936362624 | /sched/gomaxprocs:threads          |      10 |        1 |     1 | 3 | 6125793280 |
| 981359936363520 | /gc/heap/goal:bytes                | 4194304 | <nil>    |     1 | 3 | 6125793280 |
| 981359936389696 | /memory/classes/heap/objects:bytes | 4251648 | <nil>    |     1 | 3 | 6125793280 |
| 981360035561280 | /memory/classes/heap/objects:bytes | 3740904 | <nil>    | <nil> | 0 | 6125793280 |
+-----------------+------------------------------------+---------+----------+-------+---+------------+
