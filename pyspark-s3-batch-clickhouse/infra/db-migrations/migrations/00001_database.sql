-- +goose Up
-- +goose StatementBegin
CREATE DATABASE IF NOT EXISTS test_l1_raw;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP DATABASE IF EXISTS test_l1_raw;
-- +goose StatementEnd
