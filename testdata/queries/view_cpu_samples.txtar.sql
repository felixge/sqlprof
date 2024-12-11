-- sample.sql --
select distinct on (stack_id is null, g is null, p is null, m is null) *
from cpu_samples
order by end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------+----------+----------------------------------------------------------------------------------------------------------------------------------------------------------------+-------+-------+------------+
|   end_time_ns   | stack_id |                                                                          stack_funcs                                                                           |   g   |   p   |     m      |
+-----------------+----------+----------------------------------------------------------------------------------------------------------------------------------------------------------------+-------+-------+------------+
| 981359951846784 |       22 | [runtime.nanotime1 runtime.nanotime time.Since main.cpuHog main.runSleep main.run main.main runtime.main runtime.goexit]                                       |     1 |     1 | 6125219840 |
| 981360172294912 |       24 | [runtime.(*timer).modify runtime.(*timer).reset runtime.resetForSleep runtime.park_m runtime.mcall]                                                            | <nil> |     1 | 6125793280 |
| 981360937495552 |       31 | [runtime.pthread_cond_wait runtime.semasleep runtime.notesleep runtime.mPark runtime.stopm runtime.findRunnable runtime.schedule runtime.park_m runtime.mcall] | <nil> | <nil> | 6125219840 |
+-----------------+----------+----------------------------------------------------------------------------------------------------------------------------------------------------------------+-------+-------+------------+
