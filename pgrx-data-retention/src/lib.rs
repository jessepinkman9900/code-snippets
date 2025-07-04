use pgrx::bgworkers::*;
use pgrx::prelude::*;
use std::time::Duration;

/*
    In order to use this bgworker with pgrx, you'll need to edit the proper `postgresql.conf` file in
    "${PGRX_HOME}/data-$PGVER/postgresql.conf" and add this line to the end:

    ```
    shared_preload_libraries = 'bgworker.so'
    ```

    Background workers **must** be initialized in the extension's `_PG_init()` function, and can **only**
    be started if loaded through the `shared_preload_libraries` configuration setting.

    Executing `cargo pgrx run <PGVER>` will, when it restarts the specified Postgres instance, also start
    this background worker
*/

::pgrx::pg_module_magic!(name, version);

#[pg_extern]
fn hello_extention() -> &'static str {
  "Hello, extention"
}

#[pg_guard]
pub extern "C-unwind" fn _PG_init() {
  // start the background worker
  BackgroundWorkerBuilder::new("Data Retention Background Worker")
    .set_function("data_retention_bgworker_main")
    .set_library("pgrx_data_retention")
    .set_argument(42i32.into_datum())
    .enable_spi_access()
    .load();

  log!("Data Retention Background Worker initialized");
}

#[derive(Debug, Clone)]
struct DataRetentionPolicy {
  id: i32,
  schema_name: String,
  table_name: String,
  retention_days: i32,
  timestamp_column_name: String,
  batch_size: i32,
  cron_schedule: String,
  updated_at: Timestamp,
}

impl std::fmt::Display for DataRetentionPolicy {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    write!(
      f,
      "Policy[{}]: {}.{} ({}d, column: {}, batch: {}, cron: {}) updated_at: {}",
      self.id,
      self.schema_name,
      self.table_name,
      self.retention_days,
      self.timestamp_column_name,
      self.batch_size,
      self.cron_schedule,
      self.updated_at,
    )
  }
}

impl<'a> TryFrom<pgrx::spi::SpiHeapTupleData<'a>> for DataRetentionPolicy {
  type Error = pgrx::spi::Error;

  fn try_from(
    row: pgrx::spi::SpiHeapTupleData<'a>,
  ) -> Result<Self, Self::Error> {
    Ok(DataRetentionPolicy {
      id: row
        .get_datum_by_ordinal(1)
        .expect("Failed to get id")
        .value::<i32>()
        .expect("Failed to cast id to i32")
        .unwrap(),
      schema_name: row
        .get_datum_by_ordinal(3)
        .expect("Failed to get schema_name")
        .value::<String>()
        .expect("Failed to cast schema_name to String")
        .unwrap(),
      table_name: row
        .get_datum_by_ordinal(4)
        .expect("Failed to get table_name")
        .value::<String>()
        .expect("Failed to cast table_name to String")
        .unwrap(),
      retention_days: row
        .get_datum_by_ordinal(5)
        .expect("Failed to get retention_days")
        .value::<i32>()
        .expect("Failed to cast retention_days to i32")
        .unwrap(),
      timestamp_column_name: row
        .get_datum_by_ordinal(6)
        .expect("Failed to get timestamp_column_name")
        .value::<String>()
        .expect("Failed to cast timestamp_column_name to String")
        .unwrap(),
      batch_size: row
        .get_datum_by_ordinal(7)
        .expect("Failed to get batch_size")
        .value::<i32>()
        .expect("Failed to cast batch_size to i32")
        .unwrap(),
      cron_schedule: row
        .get_datum_by_ordinal(8)
        .expect("Failed to get cron_schedule")
        .value::<String>()
        .expect("Failed to cast cron_schedule to String")
        .unwrap(),
      updated_at: row
        .get_datum_by_ordinal(9)
        .expect("Failed to get updated_at")
        .value::<Timestamp>()
        .expect("Failed to cast updated_at to Timestamp")
        .unwrap(),
    })
  }
}

/// Execute a simple SELECT query to keep the connection alive and verify database connectivity
fn select_ping(client: &pgrx::spi::SpiClient) {
  let sql = "SELECT 1 + 1";
  let res = client.select(sql, None, &[]);
  if let Ok(res) = res {
    // Process each row individually
    for row in res {
      log!("Row: {}", row.columns());
      // let value: i32 = row.get::<Option<i32>>(1).expect("Failed to get column").expect("Failed to get value");
      //   log!("Result: {}", value);
      let c1 = row
        .get_datum_by_ordinal(1)
        .expect("Failed to get datum")
        .value::<i32>()
        .expect("Failed to get value");
      log!("Result: {}", c1.unwrap());
    }
  }
}

/// Drop and recreate the data retention policy configuration table
fn drop_and_create_config_table(
  client: &mut pgrx::spi::SpiClient,
) -> Result<(), pgrx::spi::Error> {
  let sql = "DROP TABLE IF EXISTS public.data_retention_policy";
  client.update(sql, None, &[]).expect("Failed to drop table");

  let sql = "CREATE TABLE IF NOT EXISTS public.data_retention_policy (
      id SERIAL PRIMARY KEY,
      schema_name TEXT NOT NULL,
      table_name TEXT NOT NULL,
      retention_days INT NOT NULL,
      timestamp_column_name TEXT NOT NULL,
      batch_size INT NOT NULL,
      cron_schedule TEXT NOT NULL,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
  client
    .update(sql, None, &[])
    .expect("Failed to create table");

  Ok(())
}

fn get_data_retention_policy(
  _client: &mut pgrx::spi::SpiClient,
) -> Result<Vec<DataRetentionPolicy>, pgrx::spi::Error> {
  let sql = "SELECT * FROM public.data_retention_policy";
  let res = _client.select(sql, None, &[]);
  if let Ok(res) = res {
    let mut policies = Vec::new();
    for row in res {
      let policy = DataRetentionPolicy::try_from(row).unwrap();
      log!("Policy: {}", policy);
      policies.push(policy);
    }

    Ok(policies)
  } else {
    Ok(Vec::new())
  }
}

/// Check if a table exists in the database
fn table_exists(
  client: &mut pgrx::spi::SpiClient,
  schema: &str,
  table: &str,
) -> bool {
  let sql = format!(
    "SELECT EXISTS (
            SELECT FROM information_schema.tables
            WHERE table_schema = '{}' AND table_name = '{}'
        )",
    schema, table
  );

  let rows = client.select(&sql, None, &[]);
  if let Ok(rows) = rows {
    for row in rows {
      let exists = row
        .get_datum_by_ordinal(1)
        .expect("Failed to get exists result")
        .value::<bool>()
        .expect("Failed to cast exists result to bool")
        .unwrap_or(false);
      return exists;
    }
    return false;
  }
  return false;
}

fn execute_policy(
  client: &mut pgrx::spi::SpiClient,
  policy: DataRetentionPolicy,
) -> Result<(), pgrx::spi::Error> {
  // Delete the oldest rows based on the retention policy
  // Batch delete based on the batch size
  log!("Executing policy: {}", policy);

  // Check if table exists first
  if !table_exists(client, &policy.schema_name, &policy.table_name) {
    log!(
      "Table {}.{} does not exist, skipping policy execution",
      policy.schema_name,
      policy.table_name
    );
    return Ok(());
  }

  // Construct SQL to delete rows older than retention_days using a CTE
  let sql = format!(
    "WITH rows_to_delete AS (
        SELECT id
        FROM {}.{}
        WHERE {} < NOW() - INTERVAL '{} days'
        ORDER BY {} ASC
        LIMIT {}
    )
    DELETE FROM {}.{}
    WHERE id IN (SELECT id FROM rows_to_delete)",
    policy.schema_name,
    policy.table_name,
    policy.timestamp_column_name,
    policy.retention_days,
    policy.timestamp_column_name,
    policy.batch_size,
    policy.schema_name,
    policy.table_name
  );

  log!("Executing SQL: {}", sql);

  // Execute the delete statement
  let result = client.update(&sql, None, &[]);
  match result {
    Ok(result) => {
      // In pgrx, for DELETE operations we need to extract the count differently
      // The number of rows affected is typically the result itself
      let rows_affected = result.len() as i64;

      log!(
        "Deleted {} rows from {}.{} batch: {} retention: {} days",
        rows_affected,
        policy.schema_name,
        policy.table_name,
        policy.batch_size,
        policy.retention_days
      );
      Ok(())
    }
    Err(e) => {
      log!("Error executing policy: {}", e);
      // Return Ok instead of Err to prevent worker from crashing
      Ok(())
    }
  }
}

/// Apply data retention policy
fn apply_data_retention_policy(
  _client: &mut pgrx::spi::SpiClient,
) -> Result<(), pgrx::spi::Error> {
  let policies = match get_data_retention_policy(_client) {
    Ok(policies) => policies,
    Err(e) => {
      log!("Error getting data retention policies: {}", e);
      return Ok(());
    }
  };

  for policy in policies {
    // Handle the Result returned by execute_policy
    if let Err(e) = execute_policy(_client, policy) {
      log!("Error executing policy: {}", e);
      // Continue with next policy even if this one failed
    }
  }

  Ok(())
}

#[pg_guard]
#[no_mangle]
pub extern "C-unwind" fn data_retention_bgworker_main(arg: pg_sys::Datum) {
  let arg = unsafe { i32::from_polymorphic_datum(arg, false, pg_sys::INT4OID) };

  // these are signals we want to receive
  // if not attached, then cannot exit via external notification
  BackgroundWorker::attach_signal_handlers(
    SignalWakeFlags::SIGHUP | SignalWakeFlags::SIGTERM,
  );

  // use SPI against the specified database as the superuser which did the initdb
  // can set second argument to Some("username") if you want to use a different user
  BackgroundWorker::connect_worker_to_spi(Some("postgres"), None);

  log!(
    "Hello from inside the {} BGWorker!  Argument value={}",
    BackgroundWorker::get_name(),
    arg.unwrap()
  );

  // create table if not exists
  let result: Result<(), pgrx::spi::Error> =
    BackgroundWorker::transaction(|| {
      Spi::connect_mut(|client| {
        drop_and_create_config_table(client).expect("Failed to create table");
        Ok(())
      })
    });
  result.unwrap_or_else(|e| panic!("Failed to create table: {}", e));

  // wake up every 10 sec or if we receive a SIGTERM
  // sleep for 10s after each iteration - no concurrent execution
  while BackgroundWorker::wait_latch(Some(Duration::from_secs(10))) {
    if BackgroundWorker::sigchld_received() {
      // on SIGHUP, might want to reload some external config
    }

    // within a txn, execute an SQL statement and log its result
    let result: Result<(), pgrx::spi::Error> =
      BackgroundWorker::transaction(|| {
        Spi::connect_mut(|client| {
          select_ping(client);
          // Try to apply data retention policy but don't crash if it fails
          if let Err(e) = apply_data_retention_policy(client) {
            log!("Error applying data retention policies: {}", e);
            // Continue execution even if policy application fails
          }
          Ok(())
        })
      });
    result.unwrap_or_else(|e| {
      log!("Error in transaction: {}, continuing execution", e)
    });
  }

  log!(
    "Goodbye from inside the {} BGWorker!",
    BackgroundWorker::get_name()
  );
}

#[cfg(any(test, feature = "pg_test"))]
#[pg_schema]
mod tests {
  use pgrx::prelude::*;

  #[pg_test]
  fn test_hello_extention() {
    assert_eq!("Hello, extention", crate::hello_extention());
  }
}

/// This module is required by `cargo pgrx test` invocations.
/// It must be visible at the root of your extension crate.
#[cfg(test)]
pub mod pg_test {
  pub fn setup(_options: Vec<&str>) {
    // perform one-off initialization when the pg_test framework starts
  }

  #[must_use]
  pub fn postgresql_conf_options() -> Vec<&'static str> {
    // return any postgresql.conf settings that are required for your tests
    vec!["shared_preload_libraries = 'pgrx_data_retention.so'"]
  }
}
