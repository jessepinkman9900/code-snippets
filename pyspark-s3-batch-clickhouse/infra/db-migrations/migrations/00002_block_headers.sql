-- +goose Up
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS test_l1_raw.block_headers (
  file_path String,
  block_time String,
  height Int64,
  hash String,
  proposer String,
  processed_at DateTime
) ENGINE = ReplacingMergeTree(processed_at)
ORDER BY (height, hash);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS test_l1_raw.block_headers;
-- +goose StatementEnd
