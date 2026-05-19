CREATE INDEX ON subway_ee (vid);
CREATE INDEX ON mappluto (vid);
CREATE INDEX ON lion (target);
CREATE INDEX ON lion (source);

    -- optional
CREATE TABLE dd_nyc AS
    SELECT
        s.id,
        s.stop_name,
        s.vid, -- need for next step
        p.id AS parcel_id,
        p.network_snap,
        p.pos_geom,
        dd.agg_cost AS nw_dist
    FROM subway_ee s
    CROSS JOIN LATERAL pgr_drivingDistance(
        'SELECT id, source, target, cost FROM lion',
        s.vid, -- subway point vertices
        1320, -- network distance (feet)
        directed := false
    ) AS dd
    JOIN mappluto p
        ON p.vid = dd.node;