use pgrx::bgworkers::*;
use pgrx::prelude::*;
use std::time::Duration;

use crate::retention::worker::spawn_data_retention_worker;
use crate::retention::DataRetentionPolicy;

pub fn init() {
  _init_guc();
  _init_bgworker();
}

fn _init_guc() {}

fn _init_bgworker() {
  BackgroundWorkerBuilder::new("Data Retention Orchestrator Worker")
    .set_function("_data_retention_orchestrator_bgworker_main")
    .set_library("pg_data_retention")
    .enable_spi_access()
    .load();
  log!("Data Retention Orchestrator bg worker initialized");
}

#[pg_guard]
#[no_mangle]
pub extern "C-unwind" fn _data_retention_orchestrator_bgworker_main(
  arg: pg_sys::Datum,
) {
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

/// Drop and recreate the data retention policy configuration table
fn drop_and_create_config_table(
  client: &mut pgrx::spi::SpiClient,
) -> Result<(), pgrx::spi::Error> {
  let sql = "DROP TABLE IF EXISTS public.data_retention_policy";
  client.update(sql, None, &[]).expect("Failed to drop table");

  let sql = "CREATE TABLE IF NOT EXISTS public.data_retention_policy (
      id SERIAL PRIMARY KEY,
      database_name TEXT NOT NULL,
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
    let worker = spawn_data_retention_worker(&policy).unwrap();
    match worker.wait_for_shutdown() {
      Ok(_) => log!(
        "Data retention worker for policy {:?} shutdown successfully",
        policy.id
      ),
      Err(e) => log!(
        "Data retention worker for policy {:?} failed to shutdown: {:?}",
        policy.id,
        e
      ),
    }
  }

  Ok(())
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
