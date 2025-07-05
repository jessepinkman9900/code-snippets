-- Create the data retention policy table
CREATE TABLE IF NOT EXISTS public.data_retention_policy (
  id SERIAL PRIMARY KEY,
  database_name TEXT NOT NULL,
  schema_name TEXT NOT NULL,
  table_name TEXT NOT NULL,
  retention_days INT NOT NULL,
  timestamp_column_name TEXT NOT NULL,
  batch_size INT NOT NULL,
  cron_schedule TEXT NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- insert some dummy data
CREATE DATABASE db1;
CREATE DATABASE db2;
-- \c db1;
-- CREATE TABLE IF NOT EXISTS db1.public.products (
--   id SERIAL PRIMARY KEY,
--   name VARCHAR(100),
--   price DECIMAL(10, 2),
--   inserted_at TIMESTAMP DEFAULT NOW(),
--   updated_at TIMESTAMP DEFAULT NOW()
-- );
-- \c db2;
-- CREATE TABLE IF NOT EXISTS db2.public.products (
--   id SERIAL PRIMARY KEY,
--   name VARCHAR(100),
--   price DECIMAL(10, 2),
--   inserted_at TIMESTAMP DEFAULT NOW(),
--   updated_at TIMESTAMP DEFAULT NOW()
-- );
-- \c postgres;
CREATE TABLE IF NOT EXISTS public.products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  price DECIMAL(10, 2),
  inserted_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
INSERT INTO public.data_retention_policy (
  database_name,
  schema_name,
  table_name,
  retention_days,
  timestamp_column_name,
  batch_size,
  cron_schedule
)
VALUES (
    'postgres',
    'public',
    'products',
    30,
    'inserted_at',
    1000,
    '0 0 * * *'
  );
INSERT INTO public.data_retention_policy (
    database_name,
    schema_name,
    table_name,
    retention_days,
    timestamp_column_name,
    batch_size,
    cron_schedule
  )
VALUES (
    'db1',
    'public',
    'products',
    30,
    'inserted_at',
    1000,
    '0 0 * * *'
  );
INSERT INTO public.data_retention_policy (
    database_name,
    schema_name,
    table_name,
    retention_days,
    timestamp_column_name,
    batch_size,
    cron_schedule
  )
VALUES (
    'db2',
    'public',
    'products',
    30,
    'inserted_at',
    1000,
    '0 0 * * *'
  );
