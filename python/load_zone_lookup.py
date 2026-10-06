import os
import pandas as pd
from sqlalchemy import create_engine

file_path = r"C:\Users\chath\Documents\nyc_taxi_project\data\taxi_zone_lookup.csv"

# Read CSV
zones = pd.read_csv(file_path)

print("CSV loaded successfully.")
print(zones.head())
print("Shape:", zones.shape)

# PostgreSQL connection
import os

DB_PASSWORD = os.getenv("POSTGRES_PASSWORD")

if not DB_PASSWORD:
    raise ValueError(
        "POSTGRES_PASSWORD environment variable is not set."
    )

engine = create_engine(
    f"postgresql+psycopg2://postgres:{DB_PASSWORD}@localhost:5432/nyc_taxi_project"
)

# Import into PostgreSQL
zones.to_sql(
    "taxi_zone_lookup",
    engine,
    if_exists="replace",
    index=False
)

# This MUST come after to_sql()
print("Taxi Zone Lookup imported successfully.")