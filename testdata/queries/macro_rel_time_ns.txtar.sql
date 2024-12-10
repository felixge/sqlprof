-- zero.sql --
select
    min(end_time_ns) AS abs_start,
    max(end_time_ns) AS abs_end,
    rel_time_ns(min(end_time_ns)) AS rel_start,
    rel_time_ns(max(end_time_ns)) AS rel_end
FROM raw_g_transitions;
-- zero.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------+-----------------+-----------+------------+
|    abs_start    |     abs_end     | rel_start |  rel_end   |
+-----------------+-----------------+-----------+------------+
| 956301026563968 | 956311025903360 |       640 | 9999340032 |
+-----------------+-----------------+-----------+------------+
