-- sample.sql --
select distinct on (stack_id is null, g is null, p is null, m is null) *
from raw_cpu_samples
order by end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------+----------+-------+-------+------------+
|   end_time_ns   | stack_id |   g   |   p   |     m      |
+-----------------+----------+-------+-------+------------+
| 965449960816896 |       25 |     1 |     1 | 6099185664 |
| 965450013452160 |       26 | <nil> |     1 | 6099185664 |
| 965453171437184 |       50 | <nil> | <nil> | 6098038784 |
+-----------------+----------+-------+-------+------------+
