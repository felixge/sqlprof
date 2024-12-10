CREATE TABLE raw_g_transitions (
    g BIGINT,
    from_state TEXT,
    to_state TEXT,
    reason TEXT,
    duration_ns BIGINT,
    end_time_ns BIGINT,
    stack_id UBIGINT,
    src_stack_id UBIGINT,
    src_g BIGINT,
    src_m BIGINT,
    src_p BIGINT
);

CREATE TABLE p_transitions (
    p BIGINT,
    from_state TEXT,
    to_state TEXT,
    duration_ns BIGINT,
    end_time_ns BIGINT,
    g BIGINT,
    m BIGINT,
);

CREATE TABLE stack_frames (
    stack_id UBIGINT,
    frame_id UBIGINT,
    position UBIGINT
);

CREATE TABLE frames (
    frame_id UBIGINT,
    address UBIGINT,
    function_id UBIGINT,
    line UBIGINT
);

CREATE TABLE functions (
    function_id UBIGINT,
    name TEXT,
    file TEXT,
);

CREATE VIEW stacks AS
SELECT
    stack_id,
    ARRAY_AGG(functions.name ORDER BY stack_frames.position) AS functions,
    ARRAY_AGG(functions.file ORDER BY stack_frames.position) AS files,
    ARRAY_AGG(frames.line ORDER BY stack_frames.position) AS lines,
    ARRAY_AGG(frames.frame_id ORDER BY stack_frames.position) AS frame_ids
FROM stack_frames
JOIN frames USING (frame_id)
JOIN functions USING (function_id)
GROUP BY stack_id;

CREATE VIEW g_transitions AS
SELECT
    raw_g_transitions.g,
    raw_g_transitions.from_state,
    raw_g_transitions.to_state,
    raw_g_transitions.reason,
    raw_g_transitions.duration_ns,
    raw_g_transitions.end_time_ns,
    raw_g_transitions.stack_id,
    stacks.functions AS stack,
    raw_g_transitions.src_stack_id,
    src_stacks.functions AS src_stack,
    raw_g_transitions.src_g,
    raw_g_transitions.src_m,
    raw_g_transitions.src_p

FROM raw_g_transitions
LEFT JOIN stacks ON raw_g_transitions.stack_id = stacks.stack_id
LEFT JOIN stacks AS src_stacks ON raw_g_transitions.src_stack_id = src_stacks.stack_id;

CREATE VIEW goroutines AS
SELECT
    g,
    coalesce(
        first(stack[len(stack):] ORDER BY end_time_ns) FILTER (WHERE stack is not null),
        first(src_stack[len(src_stack):] ORDER BY end_time_ns) FILTER (WHERE src_stack is not null)
    )[1] AS name,
    bool_or(reason = 'system goroutine wait') OR name LIKE 'runtime.%' AS is_system_goroutine,
    coalesce(sum(duration_ns) FILTER (WHERE from_state = 'running'), 0) AS running_ns,
    coalesce(sum(duration_ns) FILTER (WHERE from_state = 'runnable'), 0) AS runnable_ns,
    coalesce(sum(duration_ns) FILTER (WHERE from_state = 'syscall'), 0) AS syscall_ns,
    coalesce(sum(duration_ns) FILTER (WHERE from_state = 'waiting'), 0) AS waiting_ns,
    sum(duration_ns) AS total_ns
FROM g_transitions
GROUP BY 1
ORDER BY running_ns DESC;

CREATE VIEW procs AS
SELECT
    p,
    coalesce(sum(duration_ns) FILTER (WHERE from_state = 'running'), 0) AS running_ns,
    coalesce(sum(duration_ns) FILTER (WHERE from_state = 'idle'), 0) AS idle_ns,
    sum(duration_ns) AS total_ns
FROM p_transitions
GROUP BY 1
ORDER BY running_ns DESC;

CREATE VIEW goroutine_groups AS
SELECT
    name,
    sum(running_ns) AS running_ns,
    sum(runnable_ns) AS runnable_ns,
    sum(syscall_ns) AS syscall_ns,
    sum(waiting_ns) AS waiting_ns,
    sum(total_ns) AS total_ns,
    count(*) AS count
FROM goroutines
GROUP BY 1
ORDER BY running_ns DESC, name;