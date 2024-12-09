-- sample.sql --
select * from goroutines order by g limit 10;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+----+-----------------------------+---------------------+------------+-------------+------------+-------------+-------------+-------------+
| g  |            name             | is_system_goroutine | running_ns | runnable_ns | syscall_ns | waiting_ns  |  total_ns   | transitions |
+----+-----------------------------+---------------------+------------+-------------+------------+-------------+-------------+-------------+
|  1 | main.main                   | false               | 4948948800 |     2008640 |          0 |  5050139968 | 10001097408 |         744 |
|  2 | runtime.forcegchelper       | true                |          0 |           0 |          0 |  8999850240 |  8999850240 |          10 |
|  3 | main.chanUnblock.func1      | false               |       1344 |        8512 |          0 |    10975424 |    10985280 |           6 |
| 17 | runtime.bgsweep             | true                |       9856 |       93184 |          0 | 10000783040 | 10000886080 |          13 |
| 18 | runtime.bgscavenge          | true                |        768 |        4736 |          0 | 10000762816 | 10000768320 |          13 |
| 19 | runtime.runfinq             | true                |          0 |           0 |          0 |  8999850560 |  8999850560 |          10 |
| 20 | main.blockForever           | <nil>               |          0 |           0 |          0 |  8999850560 |  8999850560 |          10 |
| 33 | runtime/pprof.profileWriter | false               |     332928 |      592320 |          0 |  9892287296 |  9893212544 |         307 |
| 34 | runtime.gcBgMarkWorker      | true                |          0 |           0 |          0 |  8999850560 |  8999850560 |          10 |
| 35 | runtime.gcBgMarkWorker      | true                |          0 |           0 |          0 |  8999850560 |  8999850560 |          10 |
+----+-----------------------------+---------------------+------------+-------------+------------+-------------+-------------+-------------+
