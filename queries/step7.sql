ALTER TABLE ntas
    ADD COLUMN total_parcels bigint,
    ADD COLUMN access_parcels bigint,
    ADD COLUMN pct_access double precision;

ALTER TABLE mappluto
    ADD COLUMN ntaname text;