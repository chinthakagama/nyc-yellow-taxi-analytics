/*
===============================================================================
NYC Yellow Taxi Analytics — Q1 2024
07_powerbi_reporting.sql

Purpose:
Create a business-friendly reporting layer for Power BI.

Workflow:
1. Convert coded fields into readable dimensions
2. Create ordered distance bands
3. Create airport/non-airport segmentation
4. Create a streamlined Power BI reporting view
5. Validate the final reporting layer

Design principle:
Power BI connects to a curated reporting view rather than directly to the
raw transactional table. This keeps transformation logic centralised in SQL
and exposes only fields required for reporting.
===============================================================================
*/


-- 1. Create business-readable analytical view
CREATE OR REPLACE VIEW taxi_powerbi_data AS

SELECT
    *,

    -- Convert TLC payment codes into readable labels
    CASE payment_type
        WHEN 1 THEN 'Credit Card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No Charge'
        WHEN 4 THEN 'Dispute'
        WHEN 5 THEN 'Unknown'
        WHEN 6 THEN 'Voided Trip'
        ELSE 'Other'
    END AS payment_method,


    -- Create business-friendly trip-distance bands
    CASE
        WHEN trip_distance < 1
            THEN '< 1 mile'
        WHEN trip_distance < 3
            THEN '1–3 miles'
        WHEN trip_distance < 5
            THEN '3–5 miles'
        WHEN trip_distance < 10
            THEN '5–10 miles'
        WHEN trip_distance < 20
            THEN '10–20 miles'
        ELSE '20+ miles'
    END AS distance_band,


    -- Numeric sort key for Power BI
    CASE
        WHEN trip_distance < 1 THEN 1
        WHEN trip_distance < 3 THEN 2
        WHEN trip_distance < 5 THEN 3
        WHEN trip_distance < 10 THEN 4
        WHEN trip_distance < 20 THEN 5
        ELSE 6
    END AS distance_band_order,


    -- Airport segmentation
    CASE
        WHEN pickup_zone IN (
            'JFK Airport',
            'LaGuardia Airport',
            'Newark Airport'
        )
            THEN 'Airport Pickup'
        ELSE 'Non-Airport Pickup'
    END AS pickup_segment

FROM taxi_dashboard_enriched;


-- 2. Validate readable dimensions
SELECT
    payment_method,
    COUNT(*) AS trips

FROM taxi_powerbi_data

GROUP BY payment_method

ORDER BY trips DESC;


SELECT
    distance_band,
    distance_band_order,
    COUNT(*) AS trips

FROM taxi_powerbi_data

GROUP BY
    distance_band,
    distance_band_order

ORDER BY distance_band_order;


SELECT
    pickup_segment,
    COUNT(*) AS trips,
    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount

FROM taxi_powerbi_data

GROUP BY pickup_segment

ORDER BY trips DESC;


-- 3. Create streamlined Power BI reporting view
--
-- Only fields required for reporting and dashboard analysis are exposed.
-- This reduces unnecessary model width and keeps the semantic layer clear.

CREATE OR REPLACE VIEW taxi_powerbi_reporting AS

SELECT
    tpep_pickup_datetime,
    passenger_count,
    trip_distance,

    "PULocationID",
    "DOLocationID",

    fare_amount,
    tip_amount,
    tolls_amount,
    total_amount,
    "Airport_fee",

    trip_duration_minutes,
    trip_date,
    pickup_hour,
    day_of_week,
    weekday_name,
    day_type,

    tip_anomaly,

    pickup_borough,
    pickup_zone,
    dropoff_borough,
    dropoff_zone,

    payment_method,
    distance_band,
    distance_band_order,
    pickup_segment

FROM taxi_powerbi_data;


-- 4. Validate final reporting view
SELECT
    COUNT(*) AS reporting_rows,

    MIN(tpep_pickup_datetime)
        AS earliest_pickup,

    MAX(tpep_pickup_datetime)
        AS latest_pickup,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount,

    ROUND(
        AVG(trip_distance)::numeric,
        2
    ) AS avg_trip_distance,

    ROUND(
        AVG(trip_duration_minutes)::numeric,
        2
    ) AS avg_trip_duration_minutes

FROM taxi_powerbi_reporting;


-- 5. Validate airport reporting KPIs
SELECT
    pickup_segment,

    COUNT(*) AS trips,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS trip_share_pct,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount,

    ROUND(
        100.0 * SUM(total_amount)
        / SUM(SUM(total_amount)) OVER (),
        2
    ) AS total_trip_amount_share_pct,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount

FROM taxi_powerbi_reporting

GROUP BY pickup_segment

ORDER BY trips DESC;


-- 6. Final reporting-layer column check
SELECT
    ordinal_position,
    column_name,
    data_type

FROM information_schema.columns

WHERE table_name = 'taxi_powerbi_reporting'

ORDER BY ordinal_position;