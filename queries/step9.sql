UPDATE ntas n
    SET
        total_parcels = s.total_parcels,
        accessible_parcels = s.accessible_parcels
    FROM (
        SELECT
            ntaname,
            COUNT(*) AS total_parcels,
            COUNT(*) FILTER (
                WHERE final_dist <= 1320
            ) AS accessible_parcels
        FROM mappluto
        GROUP BY ntaname
    ) s
    WHERE n.ntaname = s.ntaname;