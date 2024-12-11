-- sample.sql --
select distinct on (src_stack_id is null, src_g is null, src_p is null, src_m is null) *
from cpu_samples
order by end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------+--------------+-------+-------+------------+
|   end_time_ns   | src_stack_id | src_g | src_p |   src_m    |
+-----------------+--------------+-------+-------+------------+
| 981359951846784 |           22 |     1 |     1 | 6125219840 |
| 981360172294912 |           24 | <nil> |     1 | 6125793280 |
| 981360937495552 |           31 | <nil> | <nil> | 6125219840 |
+-----------------+--------------+-------+-------+------------+
