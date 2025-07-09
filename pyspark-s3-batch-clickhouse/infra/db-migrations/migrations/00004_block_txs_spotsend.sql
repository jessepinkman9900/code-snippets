-- +goose Up
-- +goose StatementBegin
CREATE TABLE test_l1_raw.block_txs_spotsend (
  file_path String,
  block_time String,
  height Int64,
  tx_index Int64,
  actions String,
  user String,
  raw_tx_hash String,
  error String,
  action_index Int64,
  hyperliquid_chain String,
  signature_chain_id String,
  time Int64,
  amount String,
  destination String,
  token String,
  custom_md5 String,
  processed_at DateTime
) ENGINE = ReplacingMergeTree(processed_at)
ORDER BY (custom_md5)
PRIMARY KEY (custom_md5);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS test_l1_raw.block_txs_spotsend;
-- +goose StatementEnd
