-- zero.sql --
select
    min(end_time_ns) AS abs_start,
    max(end_time_ns) AS abs_end,
    rel_time_ns(min(end_time_ns)) AS rel_start,
    rel_time_ns(max(end_time_ns)) AS rel_end
FROM g_transitions;
-- zero.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------+-----------------+-----------+-------------+
|    abs_start    |     abs_end     | rel_start |   rel_end   |
+-----------------+-----------------+-----------+-------------+
| 981359936358784 | 981369937483328 |       320 | 10001124864 |
+-----------------+-----------------+-----------+-------------+
