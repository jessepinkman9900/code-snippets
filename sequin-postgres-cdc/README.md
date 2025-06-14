# Postgres CDC to Kafka using Sequin

__NOTE__: docker setup from [here](https://github.com/sequinstream/sequin/tree/main/docker)

```mermaid
graph LR
    A[Postgres] --> B[Sequin]
    B --> C[Kafka]
```

### Usage
#### Prerequisites
- [mise](https://mise.run/)
- [pre-commit](https://pre-commit.com/)
- [just](https://just.systems/)

#### Setup
```bash
just setup
```

#### Run
```bash
just up # run docker compose up
# go to sequin ui & create sink
just run # insert data
just down # run docker compose down
```

- Sequin UI: http://localhost:7376
- Grafana: http://localhost:3000
- Kafka UI: http://localhost:8088
