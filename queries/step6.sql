-------------
-- Driving distance (2)
-------------

CREATE TABLE dd_nyc_min AS
    SELECT
        dd.node AS vid,
        MIN(dd.agg_cost) AS nw_dist
    FROM subway_ee s
    CROSS JOIN LATERAL pgr_drivingDistance(
        'SELECT id, source, target, cost FROM lion',
        s.vid,
        1320,
        directed := false
    ) AS dd
    GROUP BY dd.node;

    -- create index
CREATE INDEX ON dd_nyc_min(vid);

-------------
-- Join edge, source, and target columns to mappluto from lion
-------------

    -- create spatial index
CREATE INDEX ON lion USING GIST (geom);
    
    -- join columns
ALTER TABLE mappluto
    ADD COLUMN edge_id bigint,
    ADD COLUMN source bigint,
    ADD COLUMN target bigint;

UPDATE mappluto p
    SET
        edge_id = l.id,
        source = l.source,
        target = l.target
    FROM (
        SELECT
            p2.id AS pid,
            s.id,
            s.source,
            s.target
        FROM mappluto p2
        CROSS JOIN LATERAL (
            SELECT
                id,
                source,
                target
            FROM lion
            ORDER BY geom <-> p2.network_snap
            LIMIT 1
        ) s
    ) l
    WHERE p.id = l.pid;

-------------
-- Join source and target network distances to mappluto from dd_nyc_min
-------------

    -- create indices
CREATE INDEX ON mappluto(source);
CREATE INDEX ON mappluto(target);

    -- join values
ALTER TABLE mappluto
    ADD COLUMN source_nw_dist double precision,
    ADD COLUMN target_nw_dist double precision;

UPDATE mappluto p
    SET source_nw_dist = v.nw_dist
    FROM dd_nyc_min v
    WHERE p.source = v.vid;

UPDATE mappluto p
    SET target_nw_dist = v.nw_dist
    FROM dd_nyc_min v
    WHERE p.target = v.vid;

-------------
-- Find euclidean distances
-------------

ALTER TABLE mappluto
    ADD COLUMN eu_s_dist double precision,
    ADD COLUMN eu_t_dist double precision;

UPDATE mappluto p
    SET eu_s_dist = ST_Distance(
        p.network_snap,
        v.the_geom
    )
    FROM lion_vertices_pgr v
    WHERE p.source = v.id;

UPDATE mappluto p
    SET eu_t_dist = ST_Distance(
        p.network_snap,
        v.the_geom
    )
    FROM lion_vertices_pgr v
    WHERE p.target = v.id;

-------------
-- Calculate cumulative distances
-------------

ALTER TABLE mappluto
    ADD COLUMN source_sum double precision,
    ADD COLUMN target_sum double precision;

UPDATE mappluto
    SET source_sum = source_nw_dist + eu_s_dist,
        target_sum = target_nw_dist + eu_t_dist;

-------------
-- Calculate final_dist
-------------

ALTER TABLE mappluto
    ADD COLUMN final_dist double precision;

UPDATE mappluto
    SET final_dist = CASE
        WHEN source_sum IS NULL THEN target_sum
        WHEN target_sum IS NULL THEN source_sum
        ELSE LEAST(source_sum, target_sum)
    END;

-------------
-- Create table of only parcels with access
-------------

CREATE TABLE access AS
    SELECT * FROM mappluto
    WHERE final_dist <= 1320;