-- sample.sql --
select * from goroutines order by g limit 10;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+------------------------+---------------------+------------+-------------+------------+------------+------------+-------------+
| g  |          name          | is_system_goroutine | running_ns | runnable_ns | syscall_ns | waiting_ns |  total_ns  | transitions |
+----+------------------------+---------------------+------------+-------------+------------+------------+------------+-------------+
|  1 | main.main              | false               | 4948707456 |     2309568 |          0 | 5042649984 | 9993667008 |         742 |
|  2 | runtime.forcegchelper  | true                |          0 |           0 |          0 | 8993045632 | 8993045632 |          10 |
| 17 | runtime.bgsweep        | true                |      24064 |      167488 |          0 | 9993098624 | 9993290176 |          13 |
| 18 | runtime.bgscavenge     | true                |        704 |       12736 |          0 | 9993066432 | 9993079872 |          13 |
| 19 | runtime.gcBgMarkWorker | true                |          0 |           0 |          0 | 8993045760 | 8993045760 |          10 |
| 20 | runtime.gcBgMarkWorker | true                |          0 |           0 |          0 | 8993045760 | 8993045760 |          10 |
| 21 | runtime.gcBgMarkWorker | true                |          0 |           0 |          0 | 8993045760 | 8993045760 |          10 |
| 22 | runtime.gcBgMarkWorker | true                |          0 |           0 |          0 | 8993045760 | 8993045760 |          10 |
| 23 | runtime.gcBgMarkWorker | true                |          0 |           0 |          0 | 8993045760 | 8993045760 |          10 |
| 24 | runtime.gcBgMarkWorker | true                |          0 |           0 |          0 | 8993045760 | 8993045760 |          10 |
+----+------------------------+---------------------+------------+-------------+------------+------------+------------+-------------+
