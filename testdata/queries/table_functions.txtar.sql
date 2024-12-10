-- sample.sql --
select * from functions where function_id <= 5 order by function_id;
-- sample.txt --
../testdata/testprog/go1.23.3.trace:
+-------------+--------------------------------+----------------------------------------------------------------------------------------+
| function_id |              name              |                                          file                                          |
+-------------+--------------------------------+----------------------------------------------------------------------------------------+
|           1 | runtime.traceLocker.Gomaxprocs | /opt/homebrew/Cellar/go/1.23.3/libexec/src/runtime/traceruntime.go                     |
|           2 | runtime.StartTrace             | /opt/homebrew/Cellar/go/1.23.3/libexec/src/runtime/trace.go                            |
|           3 | runtime/trace.Start            | /opt/homebrew/Cellar/go/1.23.3/libexec/src/runtime/trace/trace.go                      |
|           4 | main.generateTrace             | /Users/felix.geisendoerfer/go/src/github.com/felixge/sqlprof/testdata/testprog/main.go |
|           5 | main.run                       | /Users/felix.geisendoerfer/go/src/github.com/felixge/sqlprof/testdata/testprog/main.go |
+-------------+--------------------------------+----------------------------------------------------------------------------------------+
