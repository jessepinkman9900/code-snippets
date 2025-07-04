# Spark Batch Job to Index S3 Block Data into ClickHouse

## Stack
- AWS EMR Serverless - v7.9.0
    - Spark v3.5.5
    - Python v3.11
    - Scala v2.12
- Job Dependencies
    - jars
      - clickhouse-spark-runtime-3.5_2.12-0.8.0.jar
      - clickhouse-client-0.8.0.jar
      - clickhouse-data-0.8.0.jar
      - clickhouse-http-client-0.8.0.jar
      - httpclient5-5.2.1.jar
    - python dependencies
      - pyspark v3.5.5
      - lz4
      - msgpack



## Deployment Diagram

```mermaid
graph LR
  S3["Hyperliquid L1 S3"] --> Spark
  Spark --> ClickHouse
```

## Run on Local
0. Setup tools
```bash
just setup
```

1. Setup Infra
```bash
just init
# setup env
cp .env.example .env
# update env var
just plan
just apply
# 1. create clickhouse database & run migrations
# 2. create aws resources - iam, s3, emr

## misc infra cost
infracost auth login
infracost configure set api_key <your-infracost-api-key>
cd infra/terraform/workspaces/test && infracost breakdown --path .
```
TODO
- test interactive notebook (workspaces) & outgoing connection to clickhouse
- can i remove NAT gateway?

2. Run job
```bash
cp .env.example .env
# update env var
just clean-submit
```
