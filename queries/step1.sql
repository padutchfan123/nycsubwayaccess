ALTER TABLE mappluto
    ADD COLUMN pos_geom geometry(Point, 2263);

UPDATE mappluto
    SET pos_geom = ST_PointOnSurface(geom);