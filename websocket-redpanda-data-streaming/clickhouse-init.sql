CREATE TABLE raw_allmids (
  timestamp Int64,
  symbol String,
  price String
) ENGINE = MergeTree()
ORDER BY (timestamp, symbol);
