# jepsen-etcd

Jepsen etcd test in docker compose

```mermaid
graph LR
  control[Control
  runs the jepsen test
  insalls db in n1 using ssh
  ]
  n1[n1
  etcd node
  ]

  control --> n1
```

## Todo
- continue from here - https://github.com/jepsen-io/jepsen/blob/main/doc/tutorial/03-client.md

## Run on local

```bash
mise install

just up-build

docker exec -it control /bin/bash

# inside control container shell
cd jepsen
lein run test --node n1
```
