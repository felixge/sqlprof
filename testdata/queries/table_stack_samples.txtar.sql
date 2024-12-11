-- sample.sql --
select distinct on (type, src_stack_id is null, src_g is null, src_p is null, src_m is null, label_set_id is null) *
from stack_samples
order by type, src_stack_id, src_g, src_p, src_m, label_set_id asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+---------------+--------------+-------+------------------+--------------+-------+-------+------------+
|     type      | src_stack_id | value |   end_time_ns    | label_set_id | src_g | src_p |   src_m    |
+---------------+--------------+-------+------------------+--------------+-------+-------+------------+
| samples/count |           25 |     1 | 1032652645221248 | <nil>        | <nil> |     0 | 6139080704 |
| samples/count |           26 |     1 | 1032652679236608 | <nil>        |     1 |     0 | 6137360384 |
| samples/count |           35 |     1 | 1032657103802368 | <nil>        | <nil> | <nil> | 6137360384 |
+---------------+--------------+-------+------------------+--------------+-------+-------+------------+
../testdata/testprog/go1.23.3.cpu.pprof:
+-----------------+--------------+----------+-------------+--------------+-------+-------+-------+
|      type       | src_stack_id |  value   | end_time_ns | label_set_id | src_g | src_p | src_m |
+-----------------+--------------+----------+-------------+--------------+-------+-------+-------+
| cpu/nanoseconds |            1 | 60000000 | <nil>       | <nil>        | <nil> | <nil> | <nil> |
| cpu/nanoseconds |            2 | 10000000 | <nil>       |            1 | <nil> | <nil> | <nil> |
| samples/count   |            1 |        6 | <nil>       | <nil>        | <nil> | <nil> | <nil> |
| samples/count   |            2 |        1 | <nil>       |            1 | <nil> | <nil> | <nil> |
+-----------------+--------------+----------+-------------+--------------+-------+-------+-------+
