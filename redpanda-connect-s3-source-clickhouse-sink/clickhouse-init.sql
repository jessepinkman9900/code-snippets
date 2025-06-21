CREATE TABLE json_l1_blocks (
  height Int64,
  header String,
  transactions String
) ENGINE = MergeTree()
ORDER BY (height);
