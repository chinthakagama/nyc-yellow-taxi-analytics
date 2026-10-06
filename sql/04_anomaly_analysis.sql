/*
===============================================================================
NYC Yellow Taxi Analytics — Q1 2024
04_anomaly_analysis.sql

Purpose:
Investigate extreme observations after base data-quality cleaning and create
explicit anomaly flags for downstream reporting.

Approach:
1. Profile distance, duration and monetary extremes
2. Flag implausible implied speeds
3. Flag unusually long trip durations
4. Flag extreme tip amounts
5. Quantify anomaly prevalence
6. Create the dashboard analytical population
7. Restrict reporting to the intended Q1 2024 period

Important:
Extreme observations are investigated rather than automatically deleted.
The final dashboard layer excludes speed and duration anomalies. Tip anomalies
remain available through a flag so tip-specific measures can handle them
separately.
===============================================================================
*/


-- 1. Distance distribution
SELECT
    MIN(trip_distance) AS min_distance,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY trip_distance)
        AS median_distance,

    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY trip_distance)
        AS p95_distance,

    PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY trip_distance)
        AS p99_distance,

    MAX(trip_distance) AS max_distance

FROM taxi_analysis_final;


-- 2. Inspect longest-distance trips
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    trip_distance,
    trip_duration_minutes,
    implied_mph,
    total_amount

FROM taxi_analysis_final

ORDER BY trip_distance DESC

LIMIT 20;


-- 3. Duration distribution
SELECT
    MIN(trip_duration_minutes) AS min_duration,
    AVG(trip_duration_minutes) AS avg_duration,
    MAX(trip_duration_minutes) AS max_duration,

    COUNT(*) FILTER (
        WHERE trip_duration_minutes > 120
    ) AS trips_over_2_hours,

    COUNT(*) FILTER (
        WHERE trip_duration_minutes > 240
    ) AS trips_over_4_hours,

    COUNT(*) FILTER (
        WHERE trip_duration_minutes > 480
    ) AS trips_over_8_hours,

    COUNT(*) FILTER (
        WHERE trip_duration_minutes > 1440
    ) AS trips_over_24_hours

FROM taxi_analysis_final;


-- 4. Very short-trip investigation
SELECT
    COUNT(*) AS trips,

    MIN(trip_distance) AS min_distance,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY trip_distance)
        AS median_distance,

    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY trip_distance)
        AS p95_distance,

    MAX(trip_distance) AS max_distance,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY total_amount)
        AS median_total_amount,

    MAX(total_amount) AS max_total_amount

FROM taxi_analysis_final

WHERE trip_duration_minutes < 0.5;


-- 5. Total Trip Amount distribution
SELECT
    MIN(total_amount) AS min_total_amount,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY total_amount)
        AS median_total_amount,

    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY total_amount)
        AS p95_total_amount,

    PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY total_amount)
        AS p99_total_amount,

    MAX(total_amount) AS max_total_amount

FROM taxi_analysis_final;


-- 6. Tip distribution
SELECT
    MIN(tip_amount) AS min_tip,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY tip_amount)
        AS median_tip,

    PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY tip_amount)
        AS p99_tip,

    MAX(tip_amount) AS max_tip

FROM taxi_analysis_final;


-- 7. Create explicit anomaly flags
CREATE OR REPLACE VIEW taxi_analysis_flagged AS

SELECT
    *,

    CASE
        WHEN implied_mph > 100
            THEN TRUE
        ELSE FALSE
    END AS speed_anomaly,

    CASE
        WHEN trip_duration_minutes > 240
            THEN TRUE
        ELSE FALSE
    END AS duration_anomaly,

    CASE
        WHEN tip_amount > 100
            THEN TRUE
        ELSE FALSE
    END AS tip_anomaly

FROM taxi_analysis_final;


-- 8. Quantify anomaly prevalence
SELECT
    COUNT(*) AS total_trips,

    COUNT(*) FILTER (
        WHERE speed_anomaly
    ) AS speed_anomalies,

    COUNT(*) FILTER (
        WHERE duration_anomaly
    ) AS duration_anomalies,

    COUNT(*) FILTER (
        WHERE tip_anomaly
    ) AS tip_anomalies,

    ROUND(
        100.0 * COUNT(*) FILTER (WHERE speed_anomaly)
        / COUNT(*),
        4
    ) AS speed_anomaly_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (WHERE duration_anomaly)
        / COUNT(*),
        4
    ) AS duration_anomaly_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (WHERE tip_anomaly)
        / COUNT(*),
        4
    ) AS tip_anomaly_pct

FROM taxi_analysis_flagged;


-- 9. Create dashboard analytical population
--
-- Speed and duration anomalies are excluded from the dashboard population.
-- Tip anomalies remain in the dataset and retain their flag so that
-- tip-specific calculations can exclude them independently.
--
-- A half-open timestamp interval is used:
-- >= 2024-01-01 and < 2024-04-01
-- This captures the full Q1 2024 period without timestamp boundary ambiguity.

CREATE OR REPLACE VIEW taxi_dashboard_data AS

SELECT *
FROM taxi_analysis_flagged

WHERE
    speed_anomaly = FALSE
    AND duration_anomaly = FALSE

    AND tpep_pickup_datetime
        >= TIMESTAMP '2024-01-01 00:00:00'

    AND tpep_pickup_datetime
        < TIMESTAMP '2024-04-01 00:00:00';


-- 10. Validate final dashboard population
SELECT
    COUNT(*) AS dashboard_rows,

    MIN(tpep_pickup_datetime) AS earliest_pickup,
    MAX(tpep_pickup_datetime) AS latest_pickup,

    MIN(trip_distance) AS min_distance,
    MAX(trip_distance) AS max_distance,

    MIN(trip_duration_minutes) AS min_duration,
    MAX(trip_duration_minutes) AS max_duration,

    MIN(total_amount) AS min_total_amount,
    MAX(total_amount) AS max_total_amount

FROM taxi_dashboard_data;