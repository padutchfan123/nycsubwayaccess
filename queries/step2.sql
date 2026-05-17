-------------
-- Parcels
-------------

ALTER TABLE mappluto 
    ADD COLUMN network_snap geometry(Point, 2263);

UPDATE mappluto p
    SET network_snap = sub.snapped_geom
    FROM (
        SELECT
            p.id,
            ST_ClosestPoint(e.geom, p.pos_geom) AS snapped_geom
        FROM mappluto p
        JOIN LATERAL (
            SELECT e.geom
            FROM lion e
            ORDER BY p.pos_geom <-> e.geom
            LIMIT 1
        ) e ON true
    ) sub
    WHERE p.id = sub.id;

-------------
-- Subway points
-------------

ALTER TABLE subway_ee 
    ADD COLUMN network_snap geometry(Point, 2263);

UPDATE subway_ee s
    SET network_snap = sub.snapped_geom
    FROM (
        SELECT
            s.id,
            ST_ClosestPoint(e.geom, s.geom) AS snapped_geom
        FROM subway_ee s
        JOIN LATERAL (
            SELECT e.geom
            FROM lion e
            ORDER BY s.geom <-> e.geom
            LIMIT 1
        ) e ON true
    ) sub
    WHERE s.id = sub.id;