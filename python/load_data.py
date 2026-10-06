# 2. Environment Setup
# Installed Python libraries in Windows PowerShell:
# pip install pandas pyarrow sqlalchemy psycopg2-binary

# Purpose:
# - parquet ingestion
# - PostgreSQL connectivity
# - ETL pipeline support



# 5. Python ETL Script
# Created:
# python/load_data.py

# Purpose:
# - read parquet
# - connect PostgreSQL
# - load raw table
# Core architecture:
# pd.read_parquet()→ create_engine()→ df.to_sql()