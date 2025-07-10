# Postgres Stream Using Watermark Table

- use `COPY (..) TO STDOUT` to stream data from postgres to kafka

```mermaid
graph LR
  database[postgres] --> app[streaming-app]
  app --> kafka
```

## Run on Local
```sh
mise install
just init

# run docker & seed data - 1 table 10m rows 
just up

# run streaming app
just run
```

## TODO
- config parse & iteration w parallel stream
- parse last row & update watermark table
- pipelined query for copy
- benchmarking on 10m rows - how do i get to 10k rows per second?
  - i think. split into real-time logical replication stream & backfill job
  - have api to trigger backfill job
- check for missing data between source & sink
- prom metrics to track avg processing time & latency of wal processing
- idempotency key = sha256(row)
- copy w binary format?
- perf - logical replication vs copy

