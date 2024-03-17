-- Note: Defining this as a view causes seg faults for this kind of query.
-- select cpu_ms from pprof.cpu_time WHERE labels['local root span id'][1] = '445324626760191976';
CREATE TABLE pprof.cpu_time AS
SELECT
    values[(
        SELECT index
        FROM pprof.sample_types
        WHERE type = 'cpu' AND unit = 'nanoseconds'
    )]/1e6 AS cpu_ms,
    file,
    sample_id,
    location_ids,
    -- array_agg(samples_locations.location_id) AS location_ids,
    map_from_entries(
        array_agg({k: key, v: str} ORDER BY key) FILTER (WHERE key != '')
    ) AS labels,
    -- array_agg({key: key, val: str} ORDER BY key) FILTER (WHERE key != '') AS labels,
    -- array_agg(str) FILTER (WHERE str != '') AS label_vals
FROM pprof.samples
LEFT JOIN pprof.labels USING (sample_id)
-- LEFT JOIN unnest(samples.location_ids) AS samples_locations(location_id) ON true
GROUP BY 1,2,3,4;