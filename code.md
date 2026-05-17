---
layout: home
title: Code
---

## *Computational environment*

All queries were ran in QGIS (version 3.40.5-Bratislava) in DB Manager. The PostgreSQL server on which the data was stored and queried from had the following extensions:
- PostGIS (version 3.1.0)
- PL/pgSQL (version 1.0)
- pgRouting (version 3.1.2)

***

# Workflow diagram

### (add here)

## SQL Scripts

### Available in project [repository](https://github.com/padutchfan123/nycsubwayaccess/tree/main/queries)

# Main queries

### (Description of purpose of section 1)

***

## Step 1

Create a point on surface geometry `pos_geom` for `mappluto` tax parcels using **ST_PointOnSurface**.

```sql
ALTER TABLE mappluto
    ADD COLUMN pos_geom geometry(Point, 2263);

UPDATE mappluto
    SET pos_geom = ST_PointOnSurface(geom);
```

***

## Step 2

Create a network-snapped geometry `network_snap` for `mappluto` and `subway_ee` subway entrances and exit points, using **<->** (nearest neighbor operator) and comparing to `lion` edges.

### Parcels
```sql
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
```
### Subway points
```sql
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
```

***

## Step 3

Set up `lion` edge network for analysis using **pgr_createTopology**, and add `source`, `target`, and `cost` columns. **pgr_createTopology** creates the network vertices table `lion_vertices_pgr`.

```sql
ALTER TABLE lion 
    ADD COLUMN source BIGINT,
    ADD COLUMN target BIGINT;

    -- create topology
SELECT pgr_createTopology(
    'lion',
    0.0001,
    'geom',
    'id'
);

    -- check table
SELECT pgr_analyzeGraph(
    'lion',
    0.0001,
    'geom',
    'id'
);

ALTER TABLE lion 
    ADD COLUMN cost DOUBLE PRECISION;

UPDATE lion SET cost = ST_Length(geom);
```

***

## Step 4

Join nearest network vertex `id` as `vid` from `lion_vertices_pgr` to `mappluto` and `subway_ee` using each table's `network_snap` geometry.

### Create indices
```sql
CREATE INDEX ON lion_vertices_pgr USING GIST(the_geom);
CREATE INDEX ON mappluto USING GIST(network_snap);
CREATE INDEX ON subway_ee USING GIST(network_snap);
```
### Parcels
```sql
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
```
### Subway points
```sql
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
```

***

## Step 5

Informative network analysis using **pgr_drivingDistance**, from `subway_ee` points to all network vertices within 1320 ft (1/4 mile) network distance. Before that, create indices to prepare for final analysis queries.

### Create indices
```sql
CREATE INDEX ON subway_ee (vid);
CREATE INDEX ON mappluto (vid);
CREATE INDEX ON lion (target);
CREATE INDEX ON lion (source);
```
### Driving distance
```sql
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
```
*Note: Runtime was just over 23 minutes*

***

## Step 6

Calculative cumulative distance from each subway point to parcel `network_snap` point on surface, to create a final distance `final_dist` column.

To do this, find the *smaller* sum of the minimum `nw_dist` to a subway point + the euclidean distance to the `network_snap` parcel point for each of the two network vertices (`source` and `target`) on the edge that each `mappluto` `network_snap` parcel is on.

### Driving distance 2
Create a table of just the *minimum* distances from subway points to network vertices – this is smaller, has one row per each network `vid`, and is easier for the final distance calculation and analysis.
```sql
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
```
*Note: Runtime was just over 23 minutes*
### Join edge, source, and target columns to `mappluto` from `lion`
Use **<->** operator to find closest edge.
```sql
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
```

### Join source and target network distances to `mappluto` from `dd_nyc_min`
```sql
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
```

### Find euclidean distances from `network_snap` points to their edge's `source` and `target` vertices.
```sql
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
```
*Note: Runtime was around 23 minutes to populate each distance column*

### Calculate cumulative distances for each parcel's `source` and `target` vertices
```sql
ALTER TABLE mappluto
    ADD COLUMN source_sum double precision,
    ADD COLUMN target_sum double precision;

UPDATE mappluto
    SET source_sum = source_nw_dist + eu_s_dist,
        target_sum = target_nw_dist + eu_t_dist;
```

### Calculate `final_dist`
```sql
ALTER TABLE mappluto
    ADD COLUMN final_dist double precision;

UPDATE mappluto
    SET final_dist = CASE
        WHEN source_sum IS NULL THEN target_sum
        WHEN target_sum IS NULL THEN source_sum
        ELSE LEAST(source_sum, target_sum)
    END;
```

### Create table of only parcels with access
```sql
CREATE TABLE access AS
    SELECT * FROM mappluto
    WHERE final_dist <= 1320;
```

***

## Map

### `mappluto` parcels with a `final_dist` of 1320 or lower

![map1]()

# Analyze access

### (Description of purpose of section 2)

***

## Step 7