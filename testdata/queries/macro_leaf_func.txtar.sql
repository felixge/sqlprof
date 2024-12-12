-- duckdb-issue-15296.sql --
select terse
from stacks
where leaf_func(stack_id) = 'runtime.StartTrace';
-- duckdb-issue-15296.txt --
../testdata/testprog/go1.23.3.trace:
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                                                           terse                                                                                            |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| [runtime.StartTrace (trace.go:284) runtime/trace.Start (trace.go:125) github.com/felixge/sqlprof/internal/profile.StartTrace (profile.go:51) main.run (main.go:47) main.main (main.go:17)] |
| [runtime.StartTrace (trace.go:306) runtime/trace.Start (trace.go:125) github.com/felixge/sqlprof/internal/profile.StartTrace (profile.go:51) main.run (main.go:47) main.main (main.go:17)] |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
