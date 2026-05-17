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