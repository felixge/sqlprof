-- zero.sql --
select end_time_ns, rel_time_ns(end_time_ns) FROM raw_g_transitions ORDER BY end_time_ns ASC LIMIT 1;
-- zero.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------+--------------------------+
|   end_time_ns   | rel_time_ns(end_time_ns) |
+-----------------+--------------------------+
| 855758432930816 |                      128 |
+-----------------+--------------------------+
