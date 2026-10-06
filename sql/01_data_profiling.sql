/*
===============================================================================
NYC Yellow Taxi Analytics — Q1 2024
01_data_profiling.sql

Purpose:
Profile the cleaned taxi dataset before downstream analysis.

This script checks:
1. Dataset size
2. Date coverage
3. Schema
4. Key-field completeness
5. Location cardinality
6. Basic numerical ranges
7. Trip-duration distribution
===============================================================================
*/


-- 1. Dataset size
SELECT
    COUNT(*) AS total_rows
FROM clean_taxi_trips;


-- 2. Date coverage
SELECT
    MIN(tpep_pickup_datetime) AS earliest_pickup,
    MAX(tpep_pickup_datetime) AS latest_pickup
FROM clean_taxi_trips;


-- 3. Inspect schema
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'clean_taxi_trips'
ORDER BY ordinal_position;


-- 4. Essential-field NULL validation
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

FROM clean_taxi_trips;


-- 5. Key categorical/location cardinality
SELECT
    COUNT(DISTINCT "VendorID") AS vendor_count,
    COUNT(DISTINCT "PULocationID") AS pickup_locations,
    COUNT(DISTINCT "DOLocationID") AS dropoff_locations
FROM clean_taxi_trips;


-- 6. Basic trip-distance and monetary profiling
SELECT
    MIN(trip_distance) AS min_distance,
    AVG(trip_distance) AS avg_distance,
    MAX(trip_distance) AS max_distance,

    MIN(total_amount) AS min_total_amount,
    AVG(total_amount) AS avg_total_amount,
    MAX(total_amount) AS max_total_amount

FROM clean_taxi_trips;


-- 7. Trip-duration profiling
SELECT
    MIN(
        EXTRACT(
            EPOCH FROM (
                tpep_dropoff_datetime
                - tpep_pickup_datetime
            )
        ) / 60.0
    ) AS min_duration_minutes,

    AVG(
        EXTRACT(
            EPOCH FROM (
                tpep_dropoff_datetime
                - tpep_pickup_datetime
            )
        ) / 60.0
    ) AS avg_duration_minutes,

    MAX(
        EXTRACT(
            EPOCH FROM (
                tpep_dropoff_datetime
                - tpep_pickup_datetime
            )
        ) / 60.0
    ) AS max_duration_minutes

FROM clean_taxi_trips;


-- This consolidates original null validation, outlier validation, profiling and schema-inspection work into one readable script.