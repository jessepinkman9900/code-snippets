# jepsen-etcd

A Clojure library designed to ... well, that part is up to you.

## Run on local

```bash
mise install

just up-build

docker exec -it control /bin/bash

# inside control container shell
cd jepsen
lein run test --node n1
```
