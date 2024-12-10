-- traceEvGoStatusStack.sql --
SELECT from_state, to_state, stack, src_g, src_m, src_p, src_stack
FROM g_transitions
WHERE g = (SELECT g FROM goroutines WHERE name = 'main.blockForever')
ORDER BY end_time_ns ASC
LIMIT 2;
-- traceEvGoStatusStack.txt --
../testdata/testprog/go1.23.3.trace:
+--------------+----------+-------+-------+-------+-------+--------------------------------------------------+
|  from_state  | to_state | stack | src_g | src_m | src_p |                    src_stack                     |
+--------------+----------+-------+-------+-------+-------+--------------------------------------------------+
| undetermined | waiting  | <nil> | <nil> | <nil> | <nil> | [runtime.gopark runtime.block main.blockForever] |
| waiting      | waiting  | <nil> | <nil> | <nil> | <nil> | [runtime.gopark runtime.block main.blockForever] |
+--------------+----------+-------+-------+-------+-------+--------------------------------------------------+
