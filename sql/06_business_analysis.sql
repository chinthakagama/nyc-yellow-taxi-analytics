/*
===============================================================================
NYC Yellow Taxi Analytics — Q1 2024
06_business_analysis.sql

Purpose:
Answer key business questions using the validated and geographically enriched
Q1 2024 taxi dataset.

Analysis areas:
1. Executive KPIs
2. Monthly performance
3. Weekday demand
4. Hourly demand
5. Pickup borough performance
6. Top pickup zones by volume
7. Payment-method mix
8. Distance-band economics
9. Airport vs non-airport trips
10. Individual airport performance
11. Pickup zones by Total Trip Amount

Terminology:
total_amount is described as Total Trip Amount rather than company revenue.
===============================================================================
*/


-- 1. Executive KPIs
SELECT
    COUNT(*) AS total_trips,

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

FROM taxi_dashboard_enriched;


-- 2. Monthly performance
SELECT
    DATE_TRUNC('month', trip_date) AS month,

    COUNT(*) AS trips,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount

FROM taxi_dashboard_enriched

GROUP BY 1
ORDER BY 1;


-- 3. Demand by weekday
SELECT
    day_of_week,
    weekday_name,

    COUNT(*) AS trips,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount

FROM taxi_dashboard_enriched

GROUP BY
    day_of_week,
    weekday_name

ORDER BY day_of_week;


-- 4. Demand by pickup hour
SELECT
    pickup_hour,

    COUNT(*) AS trips,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount,

    ROUND(
        AVG(trip_duration_minutes)::numeric,
        2
    ) AS avg_duration_minutes

FROM taxi_dashboard_enriched

GROUP BY pickup_hour
ORDER BY pickup_hour;


-- 5. Pickup borough performance
SELECT
    pickup_borough,

    COUNT(*) AS trips,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount

FROM taxi_dashboard_enriched

WHERE pickup_borough IS NOT NULL
  AND pickup_borough <> ''
  AND pickup_borough <> 'Unknown'

GROUP BY pickup_borough

ORDER BY trips DESC;


-- 6. Top 15 pickup zones by trip volume
SELECT
    pickup_borough,
    pickup_zone,

    COUNT(*) AS trips,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount

FROM taxi_dashboard_enriched

WHERE pickup_zone IS NOT NULL
  AND pickup_zone <> ''

GROUP BY
    pickup_borough,
    pickup_zone

ORDER BY trips DESC

LIMIT 15;


-- 7. Payment-method mix
-- TLC payment_type codes:
-- 1 = Credit Card
-- 2 = Cash
-- 3 = No Charge
-- 4 = Dispute
-- 5 = Unknown
-- 6 = Voided Trip

SELECT
    CASE payment_type
        WHEN 1 THEN 'Credit Card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No Charge'
        WHEN 4 THEN 'Dispute'
        WHEN 5 THEN 'Unknown'
        WHEN 6 THEN 'Voided Trip'
        ELSE 'Other'
    END AS payment_method,

    COUNT(*) AS trips,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS trip_pct,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount

FROM taxi_dashboard_enriched

GROUP BY payment_type

ORDER BY trips DESC;


-- 8. Tip analysis by payment type
--
-- Extreme tip observations above $100 are excluded from this specific
-- calculation. Cash tips are generally not captured in TLC tip_amount,
-- so this query should not be interpreted as evidence that cash passengers
-- do not tip.

SELECT
    CASE payment_type
        WHEN 1 THEN 'Credit Card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No Charge'
        WHEN 4 THEN 'Dispute'
        WHEN 5 THEN 'Unknown'
        WHEN 6 THEN 'Voided Trip'
        ELSE 'Other'
    END AS payment_method,

    COUNT(*) AS trips,

    ROUND(
        AVG(tip_amount)::numeric,
        2
    ) AS avg_recorded_tip,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY tip_amount)::numeric,
        2
    ) AS median_recorded_tip,

    ROUND(
        AVG(
            CASE
                WHEN fare_amount > 0
                THEN 100.0 * tip_amount / fare_amount
            END
        )::numeric,
        2
    ) AS avg_recorded_tip_pct

FROM taxi_dashboard_enriched

WHERE tip_amount <= 100

GROUP BY payment_type

ORDER BY trips DESC;


-- 9. Distance-band economics
SELECT
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

    COUNT(*) AS trips,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS trip_pct,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount,

    ROUND(
        AVG(trip_duration_minutes)::numeric,
        2
    ) AS avg_duration_minutes,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount

FROM taxi_dashboard_enriched

GROUP BY
    CASE
        WHEN trip_distance < 1 THEN '< 1 mile'
        WHEN trip_distance < 3 THEN '1–3 miles'
        WHEN trip_distance < 5 THEN '3–5 miles'
        WHEN trip_distance < 10 THEN '5–10 miles'
        WHEN trip_distance < 20 THEN '10–20 miles'
        ELSE '20+ miles'
    END

ORDER BY MIN(trip_distance);


-- 10. Airport vs non-airport performance
SELECT
    CASE
        WHEN pickup_zone IN (
            'JFK Airport',
            'LaGuardia Airport',
            'Newark Airport'
        )
            THEN 'Airport Pickup'
        ELSE 'Non-Airport Pickup'
    END AS pickup_segment,

    COUNT(*) AS trips,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS trip_pct,

    ROUND(
        AVG(trip_distance)::numeric,
        2
    ) AS avg_distance,

    ROUND(
        AVG(trip_duration_minutes)::numeric,
        2
    ) AS avg_duration_minutes,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount

FROM taxi_dashboard_enriched

GROUP BY 1

ORDER BY trips DESC;


-- 11. Individual airport comparison
SELECT
    pickup_zone AS airport,

    COUNT(*) AS trips,

    ROUND(
        AVG(trip_distance)::numeric,
        2
    ) AS avg_distance,

    ROUND(
        AVG(trip_duration_minutes)::numeric,
        2
    ) AS avg_duration_minutes,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount

FROM taxi_dashboard_enriched

WHERE pickup_zone IN (
    'JFK Airport',
    'LaGuardia Airport',
    'Newark Airport'
)

GROUP BY pickup_zone

ORDER BY trips DESC;


-- 12. Top 15 pickup zones by Total Trip Amount
--
-- Comparing this result with the volume ranking demonstrates that the
-- highest-volume locations are not necessarily the highest-value locations.

SELECT
    pickup_borough,
    pickup_zone,

    COUNT(*) AS trips,

    ROUND(
        SUM(total_amount)::numeric,
        2
    ) AS total_trip_amount,

    ROUND(
        AVG(total_amount)::numeric,
        2
    ) AS avg_trip_amount

FROM taxi_dashboard_enriched

WHERE pickup_zone IS NOT NULL
  AND pickup_zone <> ''

GROUP BY
    pickup_borough,
    pickup_zone

ORDER BY total_trip_amount DESC

LIMIT 15;