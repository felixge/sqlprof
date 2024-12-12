-- test.sql --
select terse
from stacks
where root_func(stack_id) = 'main.main'
order by 1;
-- test.txt --
../testdata/testprog/go1.23.3.trace:
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                                                                                      terse                                                                                                                      |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| [main.chanUnblock (main.go:63) main.run (main.go:52) main.main (main.go:17)]                                                                                                                                                                    |
| [runtime.(*traceAdvancerState).start (trace.go:956) runtime.StartTrace (trace.go:309) runtime/trace.Start (trace.go:125) github.com/felixge/sqlprof/internal/profile.StartTrace (profile.go:51) main.run (main.go:47) main.main (main.go:17)]   |
| [runtime.StartTrace (trace.go:284) runtime/trace.Start (trace.go:125) github.com/felixge/sqlprof/internal/profile.StartTrace (profile.go:51) main.run (main.go:47) main.main (main.go:17)]                                                      |
| [runtime.StartTrace (trace.go:306) runtime/trace.Start (trace.go:125) github.com/felixge/sqlprof/internal/profile.StartTrace (profile.go:51) main.run (main.go:47) main.main (main.go:17)]                                                      |
| [runtime.asyncPreempt (preempt_arm64.s:47) time.Since (time.go:946) main.cpuHog.func1 (main.go:81) runtime/pprof.Do (runtime.go:51) main.cpuHog (main.go:79) main.runSleep (main.go:72) main.run (main.go:51) main.main (main.go:17)]           |
| [runtime.chanrecv1 (chan.go:489) main.chanUnblock (main.go:67) main.run (main.go:52) main.main (main.go:17)]                                                                                                                                    |
| [runtime.startTheWorld (proc.go:1457) runtime.StartTrace (trace.go:306) runtime/trace.Start (trace.go:125) github.com/felixge/sqlprof/internal/profile.StartTrace (profile.go:51) main.run (main.go:47) main.main (main.go:17)]                 |
| [runtime.traceLocker.Gomaxprocs (traceruntime.go:304) runtime.StartTrace (trace.go:283) runtime/trace.Start (trace.go:125) github.com/felixge/sqlprof/internal/profile.StartTrace (profile.go:51) main.run (main.go:47) main.main (main.go:17)] |
| [runtime.traceStartReadCPU (tracecpu.go:42) runtime.StartTrace (trace.go:308) runtime/trace.Start (trace.go:125) github.com/felixge/sqlprof/internal/profile.StartTrace (profile.go:51) main.run (main.go:47) main.main (main.go:17)]           |
| [runtime/pprof.Do (runtime.go:51) main.cpuHog (main.go:79) main.runSleep (main.go:72) main.run (main.go:51) main.main (main.go:17)]                                                                                                             |
| [runtime/trace.Start (trace.go:128) github.com/felixge/sqlprof/internal/profile.StartTrace (profile.go:51) main.run (main.go:47) main.main (main.go:17)]                                                                                        |
| [time.Sleep (time.go:300) main.runSleep (main.go:73) main.run (main.go:51) main.main (main.go:17)]                                                                                                                                              |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
