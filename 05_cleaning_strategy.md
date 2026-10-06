# NYC Yellow Taxi Data Cleaning Strategy

## 1. Objective

The purpose of the cleaning process was to transform the raw NYC TLC
Yellow Taxi trip records into a reliable analytical dataset while
preserving the original raw data for traceability.

## 2. Data Architecture

Raw source table:
raw_yellow_taxi_trips

Clean analytical table:
clean_taxi_trips

The raw table was retained unchanged. Cleaning rules were applied when
creating the separate clean table.

## 3. Cleaning Rules Applied

### Null Values

Records were excluded where essential analytical fields were null:

- passenger_count
- trip_distance
- total_amount

### Invalid Trip Distances

Records with trip_distance <= 0 were excluded.

### Invalid Financial Values

Records with negative total_amount values were excluded.

### Passenger Count

Only records with passenger_count between 1 and 6 were retained.

### Timestamp Validation

Records where drop-off occurred before pickup were excluded.

### Duplicate Records

SELECT DISTINCT was used when creating the clean table to remove
exact duplicate records.

## 4. Data Consistency Checks

Additional checks were performed for:

- fare_amount greater than total_amount
- tip_amount greater than total_amount

These checks returned zero records, indicating no violations of these
business rules in the cleaned dataset.

## 5. Outlier Assessment

Extreme values for the following fields were investigated separately:

- trip_distance
- total_amount
- trip_duration_minutes

Extreme observations should not automatically be deleted because some
may represent legitimate unusual journeys.

## 6. Final Analytical Dataset

The clean_taxi_trips table provides the validated base dataset for
subsequent SQL EDA and analytical views.

Additional derived features include:

- trip_duration_minutes
- trip_date
- pickup_hour
- day_of_week
- weekday_name

## 7. Data Quality Principle

The raw source data was preserved separately from the cleaned analytical
layer to maintain traceability and allow cleaning decisions to be
reviewed or changed without destroying the original data.





Why This Phase Matters
Most portfolio projects show:
- charts
- KPIs
- dashboards
Very few demonstrate:
- data skepticism
- anomaly detection
- quality engineering
- reproducibility
That’s what elevates the project from:
dashboard exercise

to:
analytical engineering case study.

No. It is a good first-pass cleaning layer, but I would not claim in a portfolio or interview that the data is fully cleaned yet.
What you've done is mostly rule-based validity filtering.
You handled:
✅ Essential nulls
✅ Duplicate rows (DISTINCT)
✅ Negative/impossible distances
✅ Negative/impossible totals
✅ Invalid passenger counts
✅ Impossible timestamps
That's a solid foundation.

Your Cleaning Story Is Now Strong
You can now explain this project much more convincingly:
“I initially applied deterministic cleaning rules for nulls, duplicates, timestamps, passenger counts, distances and transaction values. I then profiled approximately 8.48 million records and discovered that simple validity rules were insufficient. For example, median distance was 1.7 miles and P99.9 was 29.5 miles, while the maximum was 98,229.4 miles. I therefore derived implied speed from distance and duration to identify internally inconsistent records rather than deleting all long-distance trips. Similarly, I distinguished high but plausible fares from anomalous monetary components such as extreme tips. I preserved the raw data, maintained a clean validity layer, and used analytical views and anomaly flags so that the treatment remained transparent and reproducible.”

That is substantially stronger than saying “I removed outliers.”

| Quality issue | Evidence | Treatment |
|---|---|---|
| Zero total | 360 records with positive distance but `$0` fare/tip/tolls/total | Exclude from revenue/trip analytical dataset |
| Extreme tips | Median $2.86, P99 $17.47, P99.9 $28.20, max **$999.99** | Investigate/flag; don't use blanket percentile deletion |
| Extreme tolls | P99 $6.94, P99.9 $21.38, max $115.92 | Don't automatically remove |
| Zero duration | 129 | Exclude |
| Impossible speed | thousands of extreme implied-speed records | Exclude using a defensible physical-consistency rule |
| Extreme distance | Max 98,229.4 miles | Don't use distance alone |
| Extreme duration | Max 157.59 hours | Treat with consistency rules / analytical limit |
| High fares | Some $700–$950 trips are internally plausible | Don't use fare alone |

NYC TLC Parquet
      ↓
Python ingestion
      ↓
raw_yellow_taxi_trips
      ↓
validity rules
      ↓
clean_taxi_trips
8,480,048 rows
      ↓
derived analytical fields
      ↓
taxi_analysis_final
      ↓
anomaly flags
      ├── speed: 2,406
      ├── duration: 5,595
      └── tip: 66 retained
      ↓
dashboard filtering
      ↓
taxi_dashboard_data
8,472,047 rows


STEP 6 — BEFORE DASHBOARD
You should know:
- major outliers
- seasonality
- peak hours
- suspicious records
- skewed distributions
- null structure
- business logic
before opening Power BI/Tableau.
Otherwise the dashboard becomes:


Final base-validity clean table:
8,480,048 records

Additional records removed during final cleaning:
488

Final validation confirmed:
- zero total amounts: 0
- zero-duration trips: 0
- non-positive trip distances: 0
- invalid passenger counts: 0


## One Thing We Need to Fix Before Power BI
We haven't yet joined the TLC Taxi Zone Lookup table.
Right now:
PULocationID = 161
DOLocationID = 236

isn't useful to a dashboard user.
Power BI should show things such as:
Midtown Center
Upper East Side
JFK Airport
LaGuardia Airport

rather than just numerical location IDs.


 
## Final Analytical Anomaly Treatment

After base cleaning, the clean_taxi_trips table contained
8,480,048 records.

Further multivariate validation identified:

- 2,406 trips with implied average speed above 100 mph
- 5,595 trips with duration above 240 minutes
- 66 trips with tips above $100

Speed and duration anomalies were excluded from the standard
dashboard dataset.

Extreme tips were flagged but retained because an unusually large
tip cannot be classified as erroneous solely from its magnitude.

The final dashboard dataset contains:

8,472,047 records.

This means 8,001 records were excluded at the analytical anomaly
stage, approximately 0.094% of the clean dataset.

Extreme but internally consistent trips were retained. For example,
long-distance journeys were not removed solely because of high
distance or high total fare.

This approach avoids arbitrary percentile-based deletion and
distinguishes data validity problems from legitimate extreme
observations.


## Create the enriched analytical view
Once the lookup has been validated, we'll join it twice.
Conceptually:
                    taxi_zone_lookup
                         ↑
                  PULocationID
                         │
taxi_dashboard_data ─────┤
                         │
                  DOLocationID
                         ↓
                    taxi_zone_lookup


## architecture has matured into
Raw Parquet
     ↓
Python ingestion
     ↓
raw_yellow_taxi_trips
     ↓
base validity cleaning
     ↓
clean_taxi_trips
8,480,048
     ↓
derived features
     ↓
taxi_analysis_final
     ↓
anomaly flags
     ↓
taxi_dashboard_data
8,472,047
     ↓
Taxi Zone Lookup
     ↓
taxi_dashboard_enriched
     ↓
Business EDA
     ↓
Power BI


## Final QA assessment
Your enriched dataset has:
| Check             | Result    | Assessment |
|---|---:|---|
| Dashboard rows | **8,472,047** | Correct |
| Lookup duplicates | **0** | Correct one-to-one lookup |
| Unknown pickups (264) | 27,179 | Retain/flag |
| Unknown drop-offs (264) | 38,015 | Retain/flag |
| Outside-NYC pickups (265) | 1,386 | Retain |
| Outside-NYC drop-offs (265) | 31,569 | Retain |
| Trips <30 sec | 13,689 | Known anomaly |
| <30 sec involving 264 | 439 | Small minority |
| <30 sec involving 265 | 327 | Small minority |

Most importantly:
13,689 short trips − only 439 involving Unknown zones − only 327 involving Outside NYC.
Even allowing for possible overlap, the overwhelming majority of the short-duration records are not explained by 264/265.
So we should correct our earlier working hypothesis.
What should we do with the 13,689 short trips?
I recommend flagging them rather than deleting them.
They're only about:
13,689 / 8,472,047 ≈ 0.162%
of the dashboard dataset.
We have evidence they're operationally unusual, but we don't have sufficient evidence to prove every one is erroneous.
This gives you a strong interview explanation:
“During validation I identified 13,689 trips lasting under 30 seconds. I investigated whether these were primarily associated with the TLC Unknown or Outside-NYC location codes, but only a small proportion were. Because duration alone was insufficient to prove the records were erroneous, I documented them as a known data-quality limitation rather than arbitrarily deleting them.”

That's good analytical governance.
Cleaning phase: CLOSED
I would not keep hunting outliers now. There will always be another extreme record in 8.47 million observations.
Your pipeline is sufficiently robust for a portfolio/dashboard project.
You have preserved:
raw data
    ↓
validity-cleaned data
    ↓
derived analytical data
    ↓
anomaly treatment
    ↓
zone-enriched dashboard data

And critically, you can explain why records were removed rather than saying, “I removed outliers.”

## This gives a strong interview explanation:
“During validation I identified 13,689 trips lasting under 30 seconds. I investigated whether these were primarily associated with the TLC Unknown or Outside-NYC location codes, but only a small proportion were. Because duration alone was insufficient to prove the records were erroneous, I documented them as a known data-quality limitation rather than arbitrarily deleting them.”

That's good analytical governance.

## Final architecture
raw_yellow_taxi_trips
        ↓
clean_taxi_trips
        ↓
analytical / anomaly layers
        ↓
taxi_dashboard_data
        ↓
taxi_dashboard_enriched
        ↓
taxi_powerbi_data
        ↓
Power BI


## All three validation checks reconcile perfectly. Your SQL preparation is now complete enough for Power BI.
Final Power BI dataset

taxi_powerbi_data — 8,472,028 rows

Validation	Result
Payment labels	Correct
Distance bands	Correct and ordered
Airport segmentation	Correct
Row-count integrity	Correct
Q1 2024 boundary	Correct
Zone enrichment	Correct
Lookup uniqueness	Correct


At this point, do not keep changing the SQL dataset unless Power BI exposes a genuine issue.

## VS Code
sql/
├── cleaning SQL
├── validation SQL
├── anomaly investigation SQL
├── zone enrichment SQL
├── business EDA SQL
├── 23_powerbi_view.sql
└── 24_powerbi_reporting_view.sql