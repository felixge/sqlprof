-- query.sql --
create temporary macro gc_category(_funcs) as (
    case
        when list_contains(_funcs, 'runtime.gcBgMarkWorker') then 'background gc'
        when list_contains(_funcs, 'runtime.gcAssistAlloc') then 'gc assist'
        when list_contains(_funcs, 'gcWriteBarrier') then 'write barrier'
        when list_contains(_funcs, 'runtime.bgsweep') then 'background sweep'
    end
);

with cpu_samples as (
    select funcs(src_stack_id) as funcs, value
    from stack_samples
    where type = 'samples/count'
)

select 
    gc_category(funcs) as gc_category,
    round(sum(value) / (select sum(value) from cpu_samples) * 100, 2) as percent
from cpu_samples
where gc_category is not null
group by grouping sets ((gc_category), ())
order by 2 desc;
-- query.txt --
../testdata/testprog/go1.23.3.trace:
+-------------+---------+
| gc_category | percent |
+-------------+---------+
| <nil>       | <nil>   |
+-------------+---------+
../testdata/gcoverhead/cpu.pprof:
+------------------+---------+
|   gc_category    | percent |
+------------------+---------+
| <nil>            |   10.51 |
| background gc    |    6.56 |
| write barrier    |    1.98 |
| gc assist        |    1.53 |
| background sweep |    0.45 |
+------------------+---------+
