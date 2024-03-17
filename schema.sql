DROP SCHEMA IF EXISTS pprof CASCADE;
CREATE SCHEMA pprof;


CREATE TABLE pprof.sample_types (
    index UTINYINT,
    type TEXT,
    unit TEXT
);

CREATE TABLE pprof.samples (
    file TEXT,
    sample_id UBIGINT,
    location_ids UBIGINT[],
    values BIGINT[],
    label_ids UBIGINT[]
);

CREATE TABLE pprof.locations (
    location_id UBIGINT,
    mapping_id UBIGINT,
    address UBIGINT,
    is_folded BOOLEAN
);

CREATE TABLE pprof.lines (
    location_id UBIGINT,
    function_id UBIGINT,
    line BIGINT,
    col BIGINT
);

CREATE TABLE pprof.functions (
    function_id UBIGINT,
    name TEXT,
    system_name TEXT,
    file TEXT,
    start_line BIGINT
);

CREATE TABLE pprof.labels (
    label_id UBIGINT,
    sample_id UBIGINT,
    key TEXT,
    str TEXT,
    num BIGINT,
    num_unit TEXT
);


-- CREATE VIEW pprof.samples AS
-- SELECT *
-- FROM tmp_samples

-- CREATE VIEW samples_labels AS
-- SELECT
--     sample_id,
--     location_ids,
--     values,
--     array_agg({
--         key: labels.key,
--         str: labels.str,
--         num: labels.num,
--         num_unit: labels.num_unit
--     }) FILTER (WHERE labels.key != '') AS labels
--     -- map_from_entries(array_agg({k:labels.key, v:labels.str})) AS labels
-- FROM pprof.samples
-- LEFT JOIN unnest(label_ids) AS sample_label_ids(label_id) ON true
-- LEFT JOIN pprof.labels USING (label_id)
-- GROUP BY 1, 2, 3;

DROP TYPE IF EXISTS g_state;


DROP TABLE IF EXISTS events;
CREATE TABLE events (
    time BIGINT,
    kind TEXT,
    m BIGINT,
    p BIGINT,
    g BIGINT,
    resource TEXT, -- TODO: split Kind(ID) formatted resources
    label TEXT,
    metric_name TEXT,
    metric_value UBIGINT,
    range_name TEXT,
    range_scope TEXT,
    range_attributes TEXT[], -- TODO: MAP(TEXT, UBIGINT) is not supported by appender : /
    task_id UBIGINT,
    task_pid UBIGINT,
    task_type TEXT,
    log_category TEXT,
    log_message VARCHAR

    -- -- p/g transitions
    -- old text,
    -- new text,

    -- -- g transitions
    -- reason text
);

DROP TABLE IF EXISTS g_transitions;
CREATE TABLE g_transitions (
    time BIGINT,
    goid BIGINT,
    g BIGINT,
    m BIGINT,
    p BIGINT,
    old text,
    new text,
    reason text
);

DROP TABLE IF EXISTS p_transitions;
CREATE TABLE p_transitions (
    time BIGINT,
    procid BIGINT,
    g BIGINT,
    m BIGINT,
    p BIGINT,
    old text,
    new text
);

DROP VIEW IF EXISTS g_states;
CREATE VIEW g_states AS
SELECT DISTINCT state
FROM (
    SELECT old AS state FROM g_transitions
    UNION ALL
    SELECT new AS state FROM g_transitions
);

DROP VIEW IF EXISTS p_states;
CREATE VIEW p_states AS
SELECT DISTINCT state
FROM (
    SELECT old AS state FROM p_transitions
    UNION ALL
    SELECT new AS state FROM p_transitions
);

DROP VIEW IF EXISTS g_reasons;
CREATE VIEW g_reasons AS
SELECT DISTINCT reason
FROM g_transitions
WHERE g_transitions.reason != '';


