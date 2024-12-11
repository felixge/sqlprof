-- sample.sql --
select distinct on (address is null, inlined) *
from frames
order by frame_id;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----------+------------+-------------+------+---------+
| frame_id |  address   | function_id | line | inlined |
+----------+------------+-------------+------+---------+
|        1 | 4331032036 |           1 |  304 | <nil>   |
+----------+------------+-------------+------+---------+
../testdata/testprog/go1.23.3.cpu.pprof:
+----------+------------+-------------+------+---------+
| frame_id |  address   | function_id | line | inlined |
+----------+------------+-------------+------+---------+
|        1 | 4330988719 |           1 |  498 | false   |
|        3 | 4330903147 |           3 |   79 | true    |
+----------+------------+-------------+------+---------+
