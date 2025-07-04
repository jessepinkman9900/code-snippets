# Data Retention Background Worker
## TODO
### Feature
- create a config table that `_PG_init()` will read on `pgctl restart`
  - config table (id, database_name, user_name)
- for each row in the config table it will create a background job to apply the policy for that logical database
- use GUC to store worker specific config

## Documentation
- instructions to load it into a postgres server

### Testing
- embeded postgres testing for bgworker
- testing across pg versions
- jepsen testing?
- reference - https://github.com/timescale/pgvectorscale/tree/main/pgvectorscale

### Design choices
- limitation of BG worker is that it can only connect to the database defined at startup. it cannot switch dynamically
- therefore we need to create a bg worker for each database for which we want to apply the policy
- bg worker cannot be spawned by using a SQL statement since SQL statement run in user process & not in the background worker process
  - change in config needs postgres server restart for the `_PG_init()` to pick up the new config & create new bg workers
    - can we use some signal to notify the bg worker to reload the config?

- Background workers must be initialised in the extension's `_PG_init()` function, and can **only**
    be started if loaded through the `shared_preload_libraries` configuration setting

### V2
- single static background worker - orchestrator
- this orchestrator will read the config table & spawn a dynamic bg worker for each row in the data retention config table


## Current Implementation
- on startup it will drop `public.data_retention_policy` table if exists and create it again in `postgres` database
- it will run a cron job every 10 seconds to check if there are any rows in `public.data_retention_policy` table
- if there are rows in `public.data_retention_policy` table, it will run a background job to delete rows from the specified table based on the retention policy
  - if the table does not exist, it will skip the policy
  - if the table exists, it will delete rows from the table based on the retention policy
  - if the table exists & sql statement fails the bg worker will panic and exit. its not a catchable error


## Run on local

```bash
# setup tools & pgrx
just init

# update postgresql.conf in ${PGRX_HOME}/data-$PGVER/postgresql.conf
# $PGVER is the default version defined in Cargo.toml
# so that you run the extention with pgrx
# default pg version is 13 in Cargo.toml so update file in ${HOME}/.pgrx/data-13/postgresql.conf
shared_preload_libraries = 'pgrx_data_retention.so'

# run the extention
just run

# insert some data into the data_retention_policy table
# in the psql cli that shows up when you run `just run`
\c postgres;
INSERT INTO data_retention_policy (schema_name, table_name, retention_days, timestamp_column_name, batch_size, cron_schedule) VALUES ('public', 'user_logs', 30, 'created_at', 1000, '0 0 * * *');

INSERT INTO data_retention_policy (schema_name, table_name, retention_days, timestamp_column_name, batch_size, cron_schedule) VALUES ('public', 'events', 90, 'created_at', 500, '0 0 * * *');

# check server logs to see bg worker is running
# 13.log since default pg version is 13 in Cargo.toml
# in new terminal window
tail -f ${HOME}/.pgrx/13.log
```

```bash
# useful commands
cargo pgrx help
```

## Docker + Extension
```bash
# build  the extension & load into postgres-17
just up
```
