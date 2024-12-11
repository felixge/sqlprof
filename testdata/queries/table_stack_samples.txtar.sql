-- sample.sql --
select distinct on (type, src_stack_id is null, src_g is null, src_p is null, src_m is null) *
from stack_samples
order by type, src_stack_id, src_g, src_p, src_m asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+---------------+--------------+-------+-----------------+-------+-------+------------+
|     type      | src_stack_id | value |   end_time_ns   | src_g | src_p |   src_m    |
+---------------+--------------+-------+-----------------+-------+-------+------------+
| samples/count |           22 |     1 | 981361235764608 |     1 |     0 | 6124646400 |
| samples/count |           24 |     1 | 981360172294912 | <nil> |     1 | 6125793280 |
| samples/count |           31 |     1 | 981363367438144 | <nil> | <nil> | 6124646400 |
+---------------+--------------+-------+-----------------+-------+-------+------------+
../testdata/testprog/go1.23.3.cpu.pprof:
+-----------------+--------------+------------+-------------+-------+-------+-------+
|      type       | src_stack_id |   value    | end_time_ns | src_g | src_p | src_m |
+-----------------+--------------+------------+-------------+-------+-------+-------+
| cpu/nanoseconds |            1 | 3130000000 | <nil>       | <nil> | <nil> | <nil> |
| samples/count   |            1 |        313 | <nil>       | <nil> | <nil> | <nil> |
+-----------------+--------------+------------+-------------+-------+-------+-------+
