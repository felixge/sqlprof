-- query.sql --
create or replace temporary macro stack_category(_funcs) as (
    case
        when list_contains(_funcs, 'runtime.gcBgMarkWorker') then 'background gc'
        when list_contains(_funcs, 'runtime.bgsweep') then 'background sweep'
        when list_contains(_funcs, 'gcWriteBarrier') then 'write barrier'
        when list_contains(_funcs, 'runtime.gcAssistAlloc') then 'gc assist'
        when list_contains(_funcs, 'runtime.mallocgc') then 'allocation'
    end
);

with cpu_samples as (
    select funcs(src_stack_id) as funcs, value
    from stack_samples
    where type = 'cpu/nanoseconds'
)

select 
    stack_category(funcs) as stack_category,
    round(sum(value) / 1e9, 1) cpu_s,
    round(sum(value) / (select sum(value) from cpu_samples) * 100, 2) as percent
from cpu_samples
where stack_category(funcs) is not null
group by grouping sets ((stack_category), ())
order by 2 desc;
-- query.txt --
../testdata/testprog/go1.23.3.trace:
+----------------+-------+---------+
| stack_category | cpu_s | percent |
+----------------+-------+---------+
| <nil>          | <nil> | <nil>   |
+----------------+-------+---------+
../testdata/gcoverhead/go1.23.3.pprof:
+------------------+-------+---------+
|  stack_category  | cpu_s | percent |
+------------------+-------+---------+
| <nil>            |   2.4 |   37.36 |
| allocation       |   1.6 |   24.81 |
| write barrier    |   0.6 |    8.68 |
| background sweep |   0.1 |    1.86 |
| background gc    |   0.1 |    1.71 |
| gc assist        |     0 |    0.31 |
+------------------+-------+---------+
