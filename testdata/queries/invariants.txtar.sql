-- traceEvGoStatusStack.sql --
select from_state, to_state, funcs(stack_id), src_g, src_m, src_p, funcs(src_stack_id)
from g_transitions
where g = (select g from goroutines where name = 'main.blockForever')
order by end_time_ns asc
limit 2;
-- traceEvGoStatusStack.txt --
../testdata/testprog/go1.23.3.trace:
+--------------+----------+--------------------------------------------------+-------+-------+-------+---------------------+
|  from_state  | to_state |                 funcs(stack_id)                  | src_g | src_m | src_p | funcs(src_stack_id) |
+--------------+----------+--------------------------------------------------+-------+-------+-------+---------------------+
| undetermined | waiting  | [runtime.gopark runtime.block main.blockForever] | <nil> | <nil> | <nil> | <nil>               |
| waiting      | waiting  | [runtime.gopark runtime.block main.blockForever] | <nil> | <nil> | <nil> | <nil>               |
+--------------+----------+--------------------------------------------------+-------+-------+-------+---------------------+
-- noSrcStackWithoutSrcG.sql --
select g, from_state, to_state, end_time_ns, src_g, funcs(src_stack_id)
from g_transitions
where
    src_g is null and
    src_stack_id is not null;
-- noSrcStackWithoutSrcG.txt --
../testdata/testprog/go1.23.3.trace:
+---+------------+----------+-------------+-------+---------------------+
| g | from_state | to_state | end_time_ns | src_g | funcs(src_stack_id) |
+---+------------+----------+-------------+-------+---------------------+
+---+------------+----------+-------------+-------+---------------------+
-- goStatement.sql --
select funcs(stack_id), funcs(src_stack_id)
from g_transitions
where
    from_state = 'notexist' and
    to_state = 'runnable' and
    g = (select g from goroutines where name = 'main.chanUnblock.func1');
-- goStatement.txt --
../testdata/testprog/go1.23.3.trace:
+--------------------------+---------------------------------------+
|     funcs(stack_id)      |          funcs(src_stack_id)          |
+--------------------------+---------------------------------------+
| [main.chanUnblock.func1] | [main.chanUnblock main.run main.main] |
+--------------------------+---------------------------------------+
