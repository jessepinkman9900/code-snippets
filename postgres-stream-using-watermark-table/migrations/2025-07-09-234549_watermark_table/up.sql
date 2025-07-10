-- Your SQL goes here
CREATE TABLE IF NOT EXISTS stream_watermark (
  id SERIAL PRIMARY KEY,
  database_name TEXT NOT NULL,
  schema_name TEXT NOT NULL,
  table_name TEXT NOT NULL,
  batch_size INT NOT NULL,
  timestamp_column_name TEXT NOT NULL,
  last_seen_timestamp TIMESTAMP NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
