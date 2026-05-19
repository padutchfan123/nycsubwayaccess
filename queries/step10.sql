UPDATE ntas
    SET pct_accessible =
        (accessible_parcels::double precision
        / NULLIF(total_parcels, 0)) * 100;