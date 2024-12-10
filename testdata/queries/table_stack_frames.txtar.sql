-- sample.sql --
select * from stack_frames where stack_id <= 2 order by stack_id, position;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----------+----------+----------+
| stack_id | frame_id | position |
+----------+----------+----------+
|        1 |        1 |        0 |
|        1 |        2 |        1 |
|        1 |        3 |        2 |
|        1 |        4 |        3 |
|        1 |        5 |        4 |
|        1 |        6 |        5 |
|        2 |        7 |        0 |
|        2 |        3 |        1 |
|        2 |        4 |        2 |
|        2 |        5 |        3 |
|        2 |        6 |        4 |
+----------+----------+----------+
