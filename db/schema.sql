create table g_transitions (
    g bigint,
    from_state text,
    to_state text,
    reason text,
    duration_ns bigint,
    end_time_ns bigint,
    stack_id ubigint,
    src_stack_id ubigint,
    src_g bigint,
    src_m bigint,
    src_p bigint
);

create table p_transitions (
    p bigint,
    from_state text,
    to_state text,
    duration_ns bigint,
    end_time_ns bigint,
    src_p bigint,
    src_g bigint,
    src_m bigint
);

create table stack_samples (
    type text,
    src_stack_id ubigint,
    value bigint,
    end_time_ns bigint,
    label_set_id ubigint,
    src_g bigint,
    src_p bigint,
    src_m bigint
);

create table metrics (
    end_time_ns bigint,
    name text,
    value bigint,
    src_stack_id ubigint,
    src_g bigint,
    src_p bigint,
    src_m bigint
);

create table stack_frames (
    stack_id ubigint,
    frame_id ubigint,
    position ubigint
);

create table frames (
    frame_id ubigint,
    address ubigint,
    function_id ubigint,
    line ubigint,
    inlined bool
);

create table label_sets (
    label_set_id ubigint,
    key text,
    str_val text,
    num_val integer,
    unit text
);

create table functions (
    function_id ubigint,
    name text,
    file text,
);

create view stacks as
select
    stack_id,
    array_agg(functions.name order by stack_frames.position) as funcs,
    array_agg(concat(functions.name, ' (', concat(regexp_extract(functions.file, '[^/]+$'), ':', frames.line), ')') order by stack_frames.position) as terse,
    array_agg(concat(functions.name, case when frames.inlined then ' [inlined]' else '' end, ' (', concat(functions.file, ':', frames.line), ')') order by stack_frames.position) as full
from stack_frames
join frames using (frame_id)
join functions using (function_id)
group by stack_id;


create or replace macro labels(_label_set_id) as (
    select map_from_entries(array_agg({'k': key, 'v': case when str_val is not null then str_val else num_val::text end}))
    from label_sets _label_sets
    where _label_sets.label_set_id = _label_set_id
);

create or replace macro stack(__stack_id) as (
    with _stacks as (select stack_id as _stack_id , * exclude (stack_id) from stacks)

    select _stacks
    from _stacks
    where _stack_id = __stack_id
);

create or replace macro funcs(__stack_id) as (
    -- The funky table and column aliasing is a workaround for a bug in DuckDB:
    -- https://github.com/duckdb/duckdb/issues/15296
    -- select _funcs
    -- from (select stack_id as _stack_id, funcs as _funcs from stacks)
    -- where _stack_id = __stack_id
    select stack(__stack_id).funcs
);

create or replace macro root_func(__stack_id) as (
    select list_last(funcs(__stack_id))
);

create or replace macro leaf_func(__stack_id) as (
    select list_first(funcs(__stack_id))
);

create or replace macro contains_func(_label_set_id, s) as (
    select exists(
        select 1
        from stack_frames
        join frames using (frame_id)
        join functions using (function_id)
        where
            stack_id = _label_set_id and
            functions.name like concat('%', s, '%')
    )
);

create view goroutines as
select
    g,
    coalesce(
        first(root_func(stack_id) order by end_time_ns) filter (where stack_id is not null),
        first(root_func(src_stack_id) order by end_time_ns) filter (where src_stack_id is not null)
    ) as name,
    bool_or(reason = 'system goroutine wait') or name like 'runtime.%' as is_system_goroutine,
    coalesce(sum(duration_ns) filter (where from_state = 'running'), 0) as running_ns,
    coalesce(sum(duration_ns) filter (where from_state = 'runnable'), 0) as runnable_ns,
    coalesce(sum(duration_ns) filter (where from_state = 'syscall'), 0) as syscall_ns,
    coalesce(sum(duration_ns) filter (where from_state = 'waiting'), 0) as waiting_ns,
    sum(duration_ns) as total_ns,
    count(*) as transitions
from g_transitions
group by 1
order by running_ns desc;

create view procs as
select
    p,
    coalesce(sum(duration_ns) filter (where from_state = 'running'), 0) as running_ns,
    coalesce(sum(duration_ns) filter (where from_state = 'idle'), 0) as idle_ns,
    sum(duration_ns) as total_ns,
    count(*) as transitions
from p_transitions
group by 1
order by running_ns desc;

create view goroutine_groups as
select
    name,
    sum(running_ns) as running_ns,
    sum(runnable_ns) as runnable_ns,
    sum(syscall_ns) as syscall_ns,
    sum(waiting_ns) as waiting_ns,
    sum(total_ns) as total_ns,
    sum(transitions) as transitions,
    count(*) as count,
from goroutines
group by 1
order by running_ns desc, name;