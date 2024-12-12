-- test.sql --
select stack(stack_id)
from stacks
order by 1
limit 5;
-- test.txt --
../testdata/testprog/go1.23.3.trace:
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                                                           stack(stack_id)                                                                                            |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| []                                                                                                                                                                                                   |
| [main.chanUnblock main.run main.main]                                                                                                                                                                |
| [main.chanUnblock.func1]                                                                                                                                                                             |
| [runtime.(*guintptr).set runtime.libcCall runtime.nanotime1 runtime.nanotime time.Since main.cpuHog.func1 runtime/pprof.Do main.cpuHog main.runSleep main.run main.main runtime.main runtime.goexit] |
| [runtime.(*scavengerState).park runtime.bgscavenge]                                                                                                                                                  |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
