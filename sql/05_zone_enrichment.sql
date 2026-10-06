/*
===============================================================================
NYC Yellow Taxi Analytics — Q1 2024
05_zone_enrichment.sql

Purpose:
Validate the NYC Taxi Zone lookup and enrich the governed taxi dataset with
human-readable pickup and drop-off geography.

Workflow:
1. Inspect lookup-table size
2. Validate LocationID uniqueness
3. Inspect special/unknown lookup values
4. Check unmatched pickup LocationIDs
5. Check unmatched drop-off LocationIDs
6. Enrich trips with pickup and drop-off geography
7. Validate the enriched view

Design principle:
LEFT JOINs preserve valid trip records even where descriptive geography is
missing or classified as unknown.
===============================================================================
*/


-- 1. Inspect taxi-zone lookup
SELECT
    COUNT(*) AS lookup_rows,
    COUNT(DISTINCT "LocationID") AS unique_location_ids
FROM taxi_zone_lookup;


-- 2. Validate LocationID uniqueness
-- Expected result: no duplicate LocationIDs.
SELECT
    "LocationID",
    COUNT(*) AS duplicate_count

FROM taxi_zone_lookup

GROUP BY "LocationID"

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;


-- 3. Inspect lookup records with missing or special geography
SELECT
    "LocationID",
    "Borough",
    "Zone",
    service_zone

FROM taxi_zone_lookup

WHERE
       "Borough" IS NULL
    OR TRIM("Borough") = ''
    OR "Zone" IS NULL
    OR TRIM("Zone") = ''
    OR "Borough" = 'Unknown'

ORDER BY "LocationID";


-- 4. Check unmatched pickup LocationIDs
SELECT
    t."PULocationID",
    COUNT(*) AS trip_count

FROM taxi_dashboard_data AS t

LEFT JOIN taxi_zone_lookup AS z
    ON t."PULocationID" = z."LocationID"

WHERE z."LocationID" IS NULL

GROUP BY t."PULocationID"

ORDER BY trip_count DESC;


-- 5. Check unmatched drop-off LocationIDs
SELECT
    t."DOLocationID",
    COUNT(*) AS trip_count

FROM taxi_dashboard_data AS t

LEFT JOIN taxi_zone_lookup AS z
    ON t."DOLocationID" = z."LocationID"

WHERE z."LocationID" IS NULL

GROUP BY t."DOLocationID"

ORDER BY trip_count DESC;


-- 6. Enrich taxi trips with pickup and drop-off geography
CREATE OR REPLACE VIEW taxi_dashboard_enriched AS

SELECT
    t.*,

    -- Pickup geography
    pu."Borough" AS pickup_borough,
    pu."Zone" AS pickup_zone,
    pu.service_zone AS pickup_service_zone,

    -- Drop-off geography
    do_zone."Borough" AS dropoff_borough,
    do_zone."Zone" AS dropoff_zone,
    do_zone.service_zone AS dropoff_service_zone

FROM taxi_dashboard_data AS t

LEFT JOIN taxi_zone_lookup AS pu
    ON t."PULocationID" = pu."LocationID"

LEFT JOIN taxi_zone_lookup AS do_zone
    ON t."DOLocationID" = do_zone."LocationID";


-- 7. Validate that enrichment did not change row count
SELECT
    (SELECT COUNT(*)
     FROM taxi_dashboard_data) AS dashboard_rows,

    (SELECT COUNT(*)
     FROM taxi_dashboard_enriched) AS enriched_rows;


-- 8. Check geographic coverage after enrichment
SELECT
    COUNT(*) AS total_trips,

    COUNT(*) FILTER (
        WHERE pickup_borough IS NULL
           OR TRIM(pickup_borough) = ''
    ) AS missing_pickup_borough,

    COUNT(*) FILTER (
        WHERE pickup_zone IS NULL
           OR TRIM(pickup_zone) = ''
    ) AS missing_pickup_zone,

    COUNT(*) FILTER (
        WHERE dropoff_borough IS NULL
           OR TRIM(dropoff_borough) = ''
    ) AS missing_dropoff_borough,

    COUNT(*) FILTER (
        WHERE dropoff_zone IS NULL
           OR TRIM(dropoff_zone) = ''
    ) AS missing_dropoff_zone

FROM taxi_dashboard_enriched;


-- 9. Review pickup distribution by borough
SELECT
    pickup_borough,
    COUNT(*) AS trips

FROM taxi_dashboard_enriched

GROUP BY pickup_borough

ORDER BY trips DESC;