# pgwire-pglite

## Use
- pglite + pglite-socket to be able to use psql with pglite
- can use for running in memory postgres for testing in k8s env without access to local file system where traditional postgres cannot run
- testcontainer use the traditional image so can't use it in k8s env. they run in ci/cd pipeline since github actions gives them access to local file system

## Limitation
- only ONE connection. so cannot run servers that do connection pooling
  - need to set hikari connection pool size to 1
- SSL not supported. need to set `PGSSLMODE=disable`
- [more docs](https://pglite.dev/docs/pglite-socket#limitations-and-tips)

## TODO
- docker image running
- unable to connect to pglite server from psql on local

## Usage

```bash
# start pglite server
just server

# connect to pglite server
# password: postgres
just client
```
