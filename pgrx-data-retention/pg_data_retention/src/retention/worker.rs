use crate::retention::DataRetentionPolicy;
use pgrx::bgworkers::*;
use pgrx::prelude::*;

pub fn spawn_data_retention_worker(
  policy: &DataRetentionPolicy,
) -> Result<DynamicBackgroundWorker, DynamicBackgroundWorkerLoadError> {
  log!("Spawning data retention worker for policy: {}", policy);

  // Create a worker name that includes the policy ID and target table
  let worker_name = format!(
    "Data Retention Worker [{}] {}.{}.{}",
    policy.id, policy.database_name, policy.schema_name, policy.table_name
  );

  // Store the policy ID in the argument
  // We'll look up the policy from the database using this ID
  BackgroundWorkerBuilder::new(worker_name.as_str())
    .set_function("_data_retention_bgworker_main")
    .set_library("pg_data_retention")
    .set_argument(policy.id.into_datum())
    .set_extra(policy.to_csv().as_str())
    .set_notify_pid(unsafe { pg_sys::MyProcPid })
    .enable_spi_access()
    .load_dynamic()
}

#[pg_guard]
#[no_mangle]
pub extern "C-unwind" fn _data_retention_bgworker_main(arg: pg_sys::Datum) {
  let policy_id =
    unsafe { i32::from_polymorphic_datum(arg, false, pg_sys::INT4OID) }
      .unwrap_or(0);

  let policy_csv = BackgroundWorker::get_extra();
  let policy = DataRetentionPolicy::from_csv(policy_csv);

  BackgroundWorker::connect_worker_to_spi(
    Some(policy.database_name.as_str()),
    None,
  );

  let result: Result<(), pgrx::spi::Error> =
    BackgroundWorker::transaction(|| {
      Spi::connect_mut(|client| {
        execute_policy(client, policy).expect("Failed to execute policy");
        Ok(())
      })
    });
  result.unwrap_or_else(|e| panic!("Failed to execute policy: {}", e));

  log!(
    "Data Retention Worker for policy {} shutting down",
    policy_id
  );
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
      "Table {}.{} does not exist in db {}, skipping policy execution",
      policy.schema_name,
      policy.table_name,
      policy.database_name
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
