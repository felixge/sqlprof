-- sample.sql --
select distinct on (address is null, inlined) *
from frames
order by frame_id;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----------+------------+-------------+------+---------+
| frame_id |  address   | function_id | line | inlined |
+----------+------------+-------------+------+---------+
|        1 | 4344319460 |           1 |  304 | <nil>   |
+----------+------------+-------------+------+---------+
../testdata/testprog/go1.23.3.cpu.pprof:
+----------+------------+-------------+------+---------+
| frame_id |  address   | function_id | line | inlined |
+----------+------------+-------------+------+---------+
|        1 | 4344275587 |           1 |  368 | false   |
|       10 | 4344277643 |          10 |  649 | true    |
+----------+------------+-------------+------+---------+
