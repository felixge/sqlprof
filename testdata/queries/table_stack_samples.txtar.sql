-- sample.sql --
select distinct on (src_stack_id is null, src_g is null, src_p is null, src_m is null) *
from stack_samples
order by end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+---------------+--------------+-------+-----------------+-------+-------+------------+
|     type      | src_stack_id | value |   end_time_ns   | src_g | src_p |   src_m    |
+---------------+--------------+-------+-----------------+-------+-------+------------+
| samples/count |           22 |     1 | 981359951846784 |     1 |     1 | 6125219840 |
| samples/count |           24 |     1 | 981360172294912 | <nil> |     1 | 6125793280 |
| samples/count |           31 |     1 | 981360937495552 | <nil> | <nil> | 6125219840 |
+---------------+--------------+-------+-----------------+-------+-------+------------+
