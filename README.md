# code-snippets
Code snippets

## Blackbox Testing
- [jepsen-etcd](jepsen-etcd)
  - jepsen etcd test using docker compose

## Postgres Extensions
- [pgrx-data-retention](pgrx-data-retention)
  - pgrx extension based background worker to delete rows from a table based on a retention policy defined in a config table

## Postgres Data Movement
### Logical Replication
- [sequin-postgres-cdc](sequin-postgres-cdc)
  - use sequin to consume postgres logical replication changes & publish to kafka
- [postgres-stream-using-logical-replication](postgres-stream-using-logical-replication)
  - use debezium engine + spring boot to consume postgres logical replication changes & publish to kafka
### COPY 
- [postgres-stream-using-watermark-table](postgres-stream-using-watermark-table)
  - use `COPY (..) TO STDOUT` to stream data from postgres to kafka

## PGLite
- [pgwire-pglite](pgwire-pglite)
  - pglite + pglite-socket to be able to use psql with pglite
  - can use for running in memory postgres for testing in k8s env without access to local file system where traditional postgres cannot run

## Kube Operators
- [kubers-ingress-operator](kubers-ingress-operator)
  - pay to call api 
    - solidity smart contract for payments + k8s operator & custom ingress auth middleware to allow access upon payment using digital signature as api key

## Redpanda Connect
- [redpanda-connect-websocket-source-clickhouse-sink](redpanda-connect-websocket-source-clickhouse-sink)
  - use redpanda connect to scrape websocket & publish to redpanda topic & sink to clickhouse db
- [redpanda-connect-s3-source-clickhouse-sink](redpanda-connect-s3-source-clickhouse-sink)
  - use redpanda connect to scrape s3 & publish to redpanda topic & sink to clickhouse db

## Rust
- [rs-s3-duckdb](rs-s3-duckdb)
  - read file from 3rd party s3, parse it, write to duckdb

## Spark
- [pyspark-s3-batch-clickhouse](pyspark-s3-batch-clickhouse)
  - read file from s3, parse it, write to clickhouse
  - terraform create clickhouse server & emr serverles application

## Rule Engine
- [antlr4-parser](antlr4-parser)
  - writing a grammar & generating parser for that grammar
- [drools-rule-engine](drools-rule-engine)
  - implement API request validation using drools rule engine in spring boot

## IaaC
- [pulumi-python/clickhouse](pulumi-python/clickhouse)
  - provision clickhouse cluster using pulumi IaaC

- [terraform](terraform)
  - terraform code snippets

## Telegram Bot
- [tg-bot](tg-bot)
  - telegram bot
