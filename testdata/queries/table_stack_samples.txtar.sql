-- sample.sql --
select distinct on (type, src_stack_id is null, src_g is null, src_p is null, src_m is null) *
from stack_samples
order by type, src_stack_id, src_g, src_p, src_m asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+---------------+--------------+-------+------------------+--------------+-------+-------+------------+
|     type      | src_stack_id | value |   end_time_ns    | label_set_id | src_g | src_p |   src_m    |
+---------------+--------------+-------+------------------+--------------+-------+-------+------------+
| samples/count |           21 |     1 | 1032003039260288 | <nil>        |     1 |     0 | 6138228736 |
| samples/count |           23 |     1 | 1032001225202880 | <nil>        | <nil> |     2 | 6138802176 |
| samples/count |           31 |     1 | 1032001992656704 | <nil>        | <nil> | <nil> | 6138802176 |
+---------------+--------------+-------+------------------+--------------+-------+-------+------------+
../testdata/testprog/go1.23.3.cpu.pprof:
+-----------------+--------------+----------+-------------+--------------+-------+-------+-------+
|      type       | src_stack_id |  value   | end_time_ns | label_set_id | src_g | src_p | src_m |
+-----------------+--------------+----------+-------------+--------------+-------+-------+-------+
| cpu/nanoseconds |            1 | 10000000 | <nil>       |            1 | <nil> | <nil> | <nil> |
| samples/count   |            1 |        1 | <nil>       |            2 | <nil> | <nil> | <nil> |
+-----------------+--------------+----------+-------------+--------------+-------+-------+-------+
