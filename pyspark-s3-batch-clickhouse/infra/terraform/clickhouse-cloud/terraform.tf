terraform {
  required_providers {
    clickhouse = {
      source = "ClickHouse/clickhouse"
      version = "3.3.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
