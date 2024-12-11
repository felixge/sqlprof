-- sample.sql --
select distinct on (address is null, inlined) *
from frames
order by frame_id;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----------+------------+-------------+------+---------+
| frame_id |  address   | function_id | line | inlined |
+----------+------------+-------------+------+---------+
|        1 | 4330163684 |           1 |  304 | <nil>   |
+----------+------------+-------------+------+---------+
../testdata/testprog/go1.23.3.cpu.pprof:
+----------+------------+-------------+------+---------+
| frame_id |  address   | function_id | line | inlined |
+----------+------------+-------------+------+---------+
|        1 | 4330119811 |           1 |  368 | false   |
|       13 | 4330034795 |          13 |   79 | true    |
+----------+------------+-------------+------+---------+
