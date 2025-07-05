# Data Retention Background Worker

- on startup it will drop `public.data_retention_policy` table if exists and create it again in `postgres` database
- orchestration bg worker will sleep for 10 seconds after each policy execution
- if there are rows in `public.data_retention_policy` table, it will spawn a bg worker to delete rows from the specified table based on the retention policy
  - if the table does not exist, it will skip the policy
  - if the table exists, it will delete rows from the table based on the retention policy
  - if the table exists & sql statement fails the bg worker will panic and exit. its not a catchable error

### Config Table

| column_name            | data_type | description |
|------------------------|-----------|-------------|
| database_name          | TEXT      | logical database name |
| schema_name            | TEXT      | schema name   |
| table_name             | TEXT      | table name    |
| retention_days         | INT       | retention period in days|
| timestamp_column_name  | TEXT      | column with type timestamp in your table that can be used to determine the age of the row |
| batch_size             | INT       | rows to delete in each iteration of the bg worker |
| cron_schedule          | TEXT      | to limit number of executions per day (not yet implemented) |

### Design choices
- 1 static background worker - as long as the service is running it will keep running & try to apply the policy
  - sleep for 10s between each iteration
- policy applied by dynamic bg worker swapned by the orchestrator bg worker
- sequential execution of policies. block on previous policy bg worker to complete before starting the next policy
  - predictable execution order & resource utilization
  - if resource utilization still, you can always just lower batch size

## TODO
### Feature
- use GUC to store worker specific config

### Testing
- embeded postgres testing for bgworker
- testing across pg versions
- jepsen testing?
- reference - https://github.com/timescale/pgvectorscale/tree/main/pgvectorscale

### Instrumentation/Profiling
- growth in count of dynamically spawned bg workers
- runtime of dynamically spawned bg workers

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

INSERT INTO public.data_retention_policy (database_name, schema_name, table_name, retention_days, timestamp_column_name, batch_size, cron_schedule)
VALUES ('postgres', 'public', 'products', 30, 'inserted_at', 1000, '0 0 * * *');

INSERT INTO public.data_retention_policy (database_name, schema_name, table_name, retention_days, timestamp_column_name, batch_size, cron_schedule)
VALUES ('db1', 'public', 'products', 30, 'inserted_at', 1000, '0 0 * * *');

INSERT INTO public.data_retention_policy (database_name, schema_name, table_name, retention_days, timestamp_column_name, batch_size, cron_schedule)
VALUES ('db2', 'public', 'products', 30, 'inserted_at', 1000, '0 0 * * *');

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
