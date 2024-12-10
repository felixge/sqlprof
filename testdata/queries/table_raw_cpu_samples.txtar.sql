-- sample.sql --
select distinct on (stack_id is null, g is null, p is null, m is null) *
from raw_cpu_samples
order by end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------+----------+-------+-------+------------+
|   end_time_ns   | stack_id |   g   |   p   |     m      |
+-----------------+----------+-------+-------+------------+
| 981359951846784 |       22 |     1 |     1 | 6125219840 |
| 981360172294912 |       24 | <nil> |     1 | 6125793280 |
| 981360937495552 |       31 | <nil> | <nil> | 6125219840 |
+-----------------+----------+-------+-------+------------+
