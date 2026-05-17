CREATE INDEX ON lion_vertices_pgr USING GIST(the_geom);
CREATE INDEX ON mappluto USING GIST(network_snap);
CREATE INDEX ON subway_ee USING GIST(network_snap);

-------------
-- Parcels
-------------

ALTER TABLE mappluto 
    ADD COLUMN vid BIGINT;

UPDATE mappluto p
    SET vid = v.id
    FROM mappluto p2
    JOIN LATERAL (
        SELECT id
        FROM lion_vertices_pgr v
        ORDER BY v.the_geom <-> p2.network_snap
        LIMIT 1
    ) v ON TRUE
    WHERE p.id = p2.id;

-------------
-- Subway points
-------------

ALTER TABLE subway_ee 
    ADD COLUMN vid BIGINT;

UPDATE subway_ee s
    SET vid = v.id
    FROM subway_ee s2
    JOIN LATERAL (
        SELECT id
        FROM lion_vertices_pgr v
        ORDER BY v.the_geom <-> s2.network_snap
        LIMIT 1
    ) v ON TRUE
    WHERE s.id = s2.id;