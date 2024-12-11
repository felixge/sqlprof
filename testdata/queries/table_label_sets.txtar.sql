-- sample.sql --
select distinct on (key, str_val is null, num_val is null, unit is null) *
from label_sets
order by label_set_id, key, str_val, num_val, unit asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+--------------+-----+---------+---------+------+
| label_set_id | key | str_val | num_val | unit |
+--------------+-----+---------+---------+------+
+--------------+-----+---------+---------+------+
../testdata/testprog/go1.23.3.cpu.pprof:
+--------------+----------+---------+---------+-------+
| label_set_id |   key    | str_val | num_val | unit  |
+--------------+----------+---------+---------+-------+
|            1 | duration | 6ms     | <nil>   | <nil> |
|            1 | func     | cpuHog  | <nil>   | <nil> |
+--------------+----------+---------+---------+-------+
