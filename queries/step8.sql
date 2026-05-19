    -- create spatial indices
CREATE INDEX ON mappluto USING GIST(pos_geom);
CREATE INDEX ON ntas USING GIST(geom);

UPDATE mappluto p
    SET ntaname = n.ntaname
    FROM ntas n
    WHERE ST_Contains(
        n.geom,
        p.pos_geom
    );