# redpanda connect websocket source

## Dataflow
```mermaid
flowchart LR
  websocket_api
  source_redpanda_connect
  sink_redpanda_connect
  redpanda_cluster
  redpanda_console
  clickhouse

  websocket_api <--listen for new messages--> source_redpanda_connect
  source_redpanda_connect --push to topic - __raw-allmids__--> redpanda_cluster
  source_redpanda_connect -.ui.-> redpanda_console
  redpanda_cluster -.ui.-> redpanda_console
  redpanda_cluster --consume & parse into row json--> sink_redpanda_connect
  sink_redpanda_connect --parse row json & insert into db--> clickhouse
```

## Run
```sh
docker compose up -d
# console - http://localhost:8080
# maybe create topic - raw-allmids
```
