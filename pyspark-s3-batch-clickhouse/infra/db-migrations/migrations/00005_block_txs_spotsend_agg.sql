-- +goose Up
-- +goose StatementBegin
CREATE TABLE test_l1_raw.spot_sends_aggregated (
  token String,
  from String,
  to String,
  volume AggregateFunction(sum, Decimal(38, 18)),
  txns AggregateFunction(count, UInt64)
) ENGINE = AggregatingMergeTree()
ORDER BY (token, from, to);

CREATE MATERIALIZED VIEW test_l1_raw.spot_sends_aggregated_mv TO test_l1_raw.spot_sends_aggregated
AS 
SELECT
  token,
  user as from,
  destination as to,
  sumState(CAST(toFloat64OrZero(amount) AS Decimal(38, 18))) as volume,
  countState() as txns
FROM test_l1_raw.block_txs_spotsend
GROUP BY (token, user, destination);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS test_l1_raw.spot_sends_aggregated;
DROP TABLE IF EXISTS test_l1_raw.spot_sends_aggregated_mv;
-- +goose StatementEnd
