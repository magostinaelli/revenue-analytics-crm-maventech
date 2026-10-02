import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy import text


load_dotenv()

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")


ddl_accounts = """
CREATE TABLE IF NOT EXISTS accounts (
    account          VARCHAR(100) PRIMARY KEY,
    sector           VARCHAR(50),
    year_established INT,
    revenue          NUMERIC,
    employees        INT,
    office_location  VARCHAR(100),
    subsidiary_of    VARCHAR(100)
);
"""

with engine.begin() as conn:
    conn.execute(text(ddl_accounts))

ddl_products = """
CREATE TABLE IF NOT EXISTS products (
    product     VARCHAR(50) PRIMARY KEY,
    series      VARCHAR(50),
    sales_price NUMERIC
);
"""

with engine.begin() as conn:
    conn.execute(text(ddl_products))

ddl_sales_team = """
CREATE TABLE IF NOT EXISTS sales_team (
    sales_agent     VARCHAR(100) PRIMARY KEY,
    manager         VARCHAR(100),
    regional_office VARCHAR(50)
);
"""

with engine.begin() as conn:
    conn.execute(text(ddl_sales_team))

ddl_sales_pipeline = """
CREATE TABLE IF NOT EXISTS sales_pipeline (
    opportunity_id VARCHAR(20) PRIMARY KEY,
    sales_agent    VARCHAR(100) REFERENCES sales_team(sales_agent),
    product        VARCHAR(50) REFERENCES products(product),
    account        VARCHAR(100) REFERENCES accounts(account),
    deal_stage     VARCHAR(20),
    engage_date    DATE,
    close_date     DATE,
    close_value    NUMERIC
);
"""

with engine.begin() as conn:
    conn.execute(text(ddl_sales_pipeline))

df_accounts = pd.read_csv("accounts.csv")
df_accounts["sector"] = df_accounts["sector"].replace("technolgy", "technology")
df_accounts["office_location"] = df_accounts["office_location"].replace("Philipines", "Philippines")
df_accounts.to_sql("accounts", engine, if_exists="append", index=False)

print(f"Cargadas {len(df_accounts)} filas en accounts")

df_products = pd.read_csv("products.csv")
df_products.to_sql("products", engine, if_exists="append", index=False)

print(f"Cargadas {len(df_products)} filas en products")

df_sales_team = pd.read_csv("sales_teams.csv")
df_sales_team.to_sql("sales_team", engine, if_exists="append", index=False)

print(f"Cargadas {len(df_sales_team)} filas en sales_team")

df_sales_pipeline = pd.read_csv("sales_pipeline.csv")
df_sales_pipeline["product"] = df_sales_pipeline["product"].replace("GTXPro", "GTX Pro")
df_sales_pipeline.to_sql("sales_pipeline", engine, if_exists="append", index=False)

print(f"Cargadas {len(df_sales_pipeline)} filas en sales_pipeline")

