/*
===============================================================================
NYC Yellow Taxi Analytics — Q1 2024
03_cleaning_and_features.sql

Purpose:
Create the validated analytical layer from the raw NYC Yellow Taxi dataset
and engineer reusable features for downstream analysis.

Workflow:
1. Create clean table
2. Validate cleaning rules
3. Compare raw and clean row counts
4. Add indexes
5. Create analytical features through a view

Design principle:
The raw source table is preserved unchanged. Cleaning is performed in a
separate table, while derived analytical features are created in a view.
===============================================================================
*/


-- 1. Create clean analytical table
DROP TABLE IF EXISTS clean_taxi_trips CASCADE;

CREATE TABLE clean_taxi_trips AS

SELECT DISTINCT *
FROM raw_yellow_taxi_trips

WHERE
    -- Essential analytical fields
    passenger_count IS NOT NULL
    AND trip_distance IS NOT NULL
    AND total_amount IS NOT NULL
    AND tpep_pickup_datetime IS NOT NULL
    AND tpep_dropoff_datetime IS NOT NULL

    -- Positive trip distance
    AND trip_distance > 0

    -- Drop-off must occur after pickup
    AND tpep_dropoff_datetime > tpep_pickup_datetime

    -- Retain positive-value analytical transactions
    AND total_amount > 0

    -- Plausible passenger capacity
    AND passenger_count BETWEEN 1 AND 6;


-- 2. Validate cleaning rules
SELECT
    COUNT(*) FILTER (
        WHERE total_amount <= 0
    ) AS invalid_total_amount,

    COUNT(*) FILTER (
        WHERE tpep_dropoff_datetime <= tpep_pickup_datetime
    ) AS invalid_duration,

    COUNT(*) FILTER (
        WHERE trip_distance <= 0
    ) AS invalid_distance,

    COUNT(*) FILTER (
        WHERE passenger_count < 1
           OR passenger_count > 6
    ) AS invalid_passenger_count

FROM clean_taxi_trips;


-- 3. Quantify cleaning impact
SELECT
    (SELECT COUNT(*)
     FROM raw_yellow_taxi_trips) AS raw_rows,

    (SELECT COUNT(*)
     FROM clean_taxi_trips) AS clean_rows,

    (SELECT COUNT(*)
     FROM raw_yellow_taxi_trips)
    -
    (SELECT COUNT(*)
     FROM clean_taxi_trips) AS rows_removed;


-- 4. Create indexes for frequently used analytical fields
CREATE INDEX IF NOT EXISTS idx_pickup_datetime
ON clean_taxi_trips(tpep_pickup_datetime);

CREATE INDEX IF NOT EXISTS idx_pickup_location
ON clean_taxi_trips("PULocationID");


-- 5. Verify indexes
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'clean_taxi_trips'
ORDER BY indexname;


-- 6. Create analytical feature view
CREATE OR REPLACE VIEW taxi_analysis_final AS

SELECT
    *,

    -- Trip duration in minutes
    EXTRACT(
        EPOCH FROM (
            tpep_dropoff_datetime
            - tpep_pickup_datetime
        )
    ) / 60.0 AS trip_duration_minutes,


    -- Implied average trip speed in miles per hour
    trip_distance /
    NULLIF(
        EXTRACT(
            EPOCH FROM (
                tpep_dropoff_datetime
                - tpep_pickup_datetime
            )
        ) / 3600.0,
        0
    ) AS implied_mph,


    -- Calendar date
    DATE(tpep_pickup_datetime) AS trip_date,


    -- Pickup hour (0–23)
    EXTRACT(
        HOUR FROM tpep_pickup_datetime
    )::INTEGER AS pickup_hour,


    -- PostgreSQL DOW:
    -- Sunday = 0 through Saturday = 6
    EXTRACT(
        DOW FROM tpep_pickup_datetime
    )::INTEGER AS day_of_week,


    -- Human-readable weekday
    TRIM(
        TO_CHAR(tpep_pickup_datetime, 'Day')
    ) AS weekday_name,


    -- Weekday/weekend segmentation
    CASE
        WHEN EXTRACT(
            DOW FROM tpep_pickup_datetime
        ) IN (0, 6)
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type

FROM clean_taxi_trips;


-- 7. Validate engineered features
SELECT
    COUNT(*) AS analytical_rows,

    MIN(trip_duration_minutes)
        AS min_duration_minutes,

    AVG(trip_duration_minutes)
        AS avg_duration_minutes,

    MAX(trip_duration_minutes)
        AS max_duration_minutes,

    MIN(implied_mph)
        AS min_implied_mph,

    MAX(implied_mph)
        AS max_implied_mph

FROM taxi_analysis_final;