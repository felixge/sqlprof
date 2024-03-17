-- Note: Defining this as a view causes seg faults for this kind of query.
-- select cpu_ms from pprof.cpu_time WHERE labels['local root span id'][1] = '445324626760191976';
CREATE TABLE pprof.cpu_time AS
SELECT
    values[(
        SELECT index
        FROM pprof.sample_types
        WHERE type = 'cpu' AND unit = 'nanoseconds'
    )]/1e6 AS cpu_ms,
    location_ids,
    file,
    sample_id,
    map_from_entries(
        array_agg({k: key, v: str} ORDER BY key) FILTER (WHERE key != '')
    ) AS labels,
    -- array_agg({key: key, val: str} ORDER BY key) FILTER (WHERE key != '') AS labels,
    -- array_agg(str) FILTER (WHERE str != '') AS label_vals
FROM pprof.samples
LEFT JOIN pprof.labels USING (sample_id)
GROUP BY 1,2,3,4;