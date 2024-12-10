-- sample.sql --
select distinct on (stack_id is null, g is null, p is null, m is null) *
from cpu_samples
order by end_time_ns asc;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+-----------------+----------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------+-------+------------+
|   end_time_ns   | stack_id |                                                                                                    stack                                                                                                    |   g   |   p   |     m      |
+-----------------+----------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------+-------+------------+
| 965449960816896 |       25 | [runtime.nanotime1 runtime.nanotime time.Since main.cpuHog main.runSleep main.generateTrace main.run main.main runtime.main runtime.goexit]                                                                 |     1 |     1 | 6099185664 |
| 965450013452160 |       26 | [runtime.kevent runtime.wakeNetpoll runtime.netpollBreak runtime.wakeNetPoller runtime.(*timer).maybeAdd runtime.(*timer).modify runtime.(*timer).reset runtime.resetForSleep runtime.park_m runtime.mcall] | <nil> |     1 | 6099185664 |
| 965453171437184 |       50 | [runtime.pthread_cond_wait runtime.semasleep runtime.notesleep runtime.mPark runtime.stopm runtime.findRunnable runtime.schedule runtime.park_m runtime.mcall]                                              | <nil> | <nil> | 6098038784 |
+-----------------+----------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------+-------+------------+
