/*
===============================================================================
NYC Yellow Taxi Analytics — Q1 2024
02_data_quality_checks.sql

Purpose:
Assess data quality in the raw NYC Yellow Taxi dataset before creating the
clean analytical layer.

Checks include:
1. NULLs in essential analytical fields
2. Invalid timestamps
3. Non-positive trip distances
4. Non-positive total trip amounts
5. Implausible passenger counts
6. Potential duplicate trips
7. Monetary consistency checks

Important:
These queries are diagnostic. They are used to understand data-quality issues
before deciding which records should be excluded or retained.
===============================================================================
*/


-- 1. Essential-field NULL assessment
SELECT
    COUNT(*) AS total_rows,

    COUNT(*) - COUNT(passenger_count)
        AS null_passenger_count,

    COUNT(*) - COUNT(trip_distance)
        AS null_trip_distance,

    COUNT(*) - COUNT(total_amount)
        AS null_total_amount,

    COUNT(*) - COUNT(tpep_pickup_datetime)
        AS null_pickup_datetime,

    COUNT(*) - COUNT(tpep_dropoff_datetime)
        AS null_dropoff_datetime

FROM raw_yellow_taxi_trips;


-- 2. Invalid timestamp sequence
-- A drop-off earlier than pickup is not physically valid.
SELECT
    COUNT(*) AS invalid_timestamp_rows
FROM raw_yellow_taxi_trips
WHERE tpep_dropoff_datetime < tpep_pickup_datetime;


-- 3. Zero-duration trips
-- Investigated separately before the final cleaning decision.
SELECT
    COUNT(*) AS zero_duration_rows
FROM raw_yellow_taxi_trips
WHERE tpep_dropoff_datetime = tpep_pickup_datetime;


-- 4. Non-positive trip distance
SELECT
    COUNT(*) AS non_positive_distance_rows
FROM raw_yellow_taxi_trips
WHERE trip_distance <= 0;


-- 5. Non-positive total trip amount
SELECT
    COUNT(*) AS non_positive_total_amount_rows
FROM raw_yellow_taxi_trips
WHERE total_amount <= 0;


-- 6. Passenger-count distribution
-- Used to identify missing or implausible passenger counts.
SELECT
    passenger_count,
    COUNT(*) AS trip_count
FROM raw_yellow_taxi_trips
GROUP BY passenger_count
ORDER BY passenger_count;


-- 7. Explicit invalid passenger-count check
SELECT
    COUNT(*) AS invalid_passenger_count_rows
FROM raw_yellow_taxi_trips
WHERE passenger_count IS NULL
   OR passenger_count < 1
   OR passenger_count > 6;


-- 8. Potential duplicate detection
-- This business-key combination was used to investigate repeated trip records.
SELECT
    "VendorID",
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    "PULocationID",
    "DOLocationID",
    COUNT(*) AS duplicate_count

FROM raw_yellow_taxi_trips

GROUP BY
    "VendorID",
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    "PULocationID",
    "DOLocationID"

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;


-- 9. Fare greater than total amount
-- Not automatically deleted: investigated as a consistency check.
SELECT
    COUNT(*) AS fare_above_total_rows
FROM raw_yellow_taxi_trips
WHERE fare_amount > total_amount;


-- 10. Tip greater than total amount
-- Also treated as an investigation flag rather than automatic deletion.
SELECT
    COUNT(*) AS tip_above_total_rows
FROM raw_yellow_taxi_trips
WHERE tip_amount > total_amount;