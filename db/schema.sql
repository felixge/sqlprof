create table raw_g_transitions (
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

create table raw_cpu_samples (
    end_time_ns bigint,
    stack_id ubigint,
    g bigint,
    p bigint,
    m bigint
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
    line ubigint
);

create table functions (
    function_id ubigint,
    name text,
    file text,
);

create view stacks as
select
    stack_id,
    array_agg(functions.name order by stack_frames.position) as functions,
    array_agg(functions.file order by stack_frames.position) as files,
    array_agg(frames.line order by stack_frames.position) as lines,
    array_agg(frames.frame_id order by stack_frames.position) as frame_ids
from stack_frames
join frames using (frame_id)
join functions using (function_id)
group by stack_id;

create view g_transitions as
select
    raw_g_transitions.g,
    raw_g_transitions.from_state,
    raw_g_transitions.to_state,
    raw_g_transitions.reason,
    raw_g_transitions.duration_ns,
    raw_g_transitions.end_time_ns,
    raw_g_transitions.stack_id,
    stacks.functions as stack,
    raw_g_transitions.src_stack_id,
    src_stacks.functions as src_stack,
    raw_g_transitions.src_g,
    raw_g_transitions.src_m,
    raw_g_transitions.src_p
from raw_g_transitions
left join stacks on raw_g_transitions.stack_id = stacks.stack_id
left join stacks as src_stacks on raw_g_transitions.src_stack_id = src_stacks.stack_id;

create view cpu_samples as
select
    raw_cpu_samples.end_time_ns,
    raw_cpu_samples.stack_id,
    stacks.functions AS stack,
    raw_cpu_samples.g,
    raw_cpu_samples.p,
    raw_cpu_samples.m
from raw_cpu_samples
left join stacks using (stack_id);

create view goroutines as
select
    g,
    coalesce(
        first(stack[len(stack):] order by end_time_ns) filter (where stack is not null),
        first(src_stack[len(src_stack):] order by end_time_ns) filter (where src_stack is not null)
    )[1] as name,
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