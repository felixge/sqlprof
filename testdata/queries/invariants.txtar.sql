-- traceEvGoStatusStack.sql --
select from_state, to_state, funcs, src_g, src_m, src_p, src_funcs
from g_transitions
where g = (select g from goroutines where name = 'main.blockForever')
order by end_time_ns asc
limit 2;
-- traceEvGoStatusStack.txt --
../testdata/testprog/go1.23.3.trace:
+--------------+----------+--------------------------------------------------+-------+-------+-------+-----------+
|  from_state  | to_state |                      funcs                       | src_g | src_m | src_p | src_funcs |
+--------------+----------+--------------------------------------------------+-------+-------+-------+-----------+
| undetermined | waiting  | [runtime.gopark runtime.block main.blockForever] | <nil> | <nil> | <nil> | <nil>     |
| waiting      | waiting  | [runtime.gopark runtime.block main.blockForever] | <nil> | <nil> | <nil> | <nil>     |
+--------------+----------+--------------------------------------------------+-------+-------+-------+-----------+
-- noSrcStackWithoutSrcG.sql --
select g, from_state, to_state, end_time_ns, src_g, src_funcs
from g_transitions
where
    src_g is null and
    src_funcs is not null;
-- noSrcStackWithoutSrcG.txt --
../testdata/testprog/go1.23.3.trace:
+---+------------+----------+-------------+-------+-----------+
| g | from_state | to_state | end_time_ns | src_g | src_funcs |
+---+------------+----------+-------------+-------+-----------+
+---+------------+----------+-------------+-------+-----------+
-- goStatement.sql --
select funcs, src_funcs
from g_transitions
where
    from_state = 'notexist' and
    to_state = 'runnable' and
    g = (select g from goroutines where name = 'main.chanUnblock.func1');
-- goStatement.txt --
../testdata/testprog/go1.23.3.trace:
+--------------------------+---------------------------------------+
|          funcs           |               src_funcs               |
+--------------------------+---------------------------------------+
| [main.chanUnblock.func1] | [main.chanUnblock main.run main.main] |
+--------------------------+---------------------------------------+
