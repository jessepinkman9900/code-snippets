use std::str::FromStr;

use pgrx::datum::Timestamp;
use pgrx::pg_schema;

pub mod orchestrator;
pub mod worker;

#[derive(Debug, Clone)]
pub struct DataRetentionPolicy {
  pub id: i32,
  pub database_name: String,
  pub schema_name: String,
  pub table_name: String,
  pub retention_days: i32,
  pub timestamp_column_name: String,
  pub batch_size: i32,
  pub cron_schedule: String,
  pub updated_at: Timestamp,
}

impl DataRetentionPolicy {
  pub fn to_csv(&self) -> String {
    format!(
      "{}, {}, {}, {}, {}, {}, {}, {}, {}",
      self.id,
      self.database_name,
      self.schema_name,
      self.table_name,
      self.retention_days,
      self.timestamp_column_name,
      self.batch_size,
      self.cron_schedule,
      self.updated_at,
    )
  }

  pub fn from_csv(csv: &str) -> DataRetentionPolicy {
    let mut fields = csv.split(',');
    DataRetentionPolicy {
      id: fields.next().unwrap().to_string().trim().parse().unwrap(),
      database_name: fields.next().unwrap().to_string().trim().to_string(),
      schema_name: fields.next().unwrap().to_string().trim().to_string(),
      table_name: fields.next().unwrap().to_string().trim().to_string(),
      retention_days: fields
        .next()
        .unwrap()
        .to_string()
        .trim()
        .parse()
        .unwrap(),
      timestamp_column_name: fields
        .next()
        .unwrap()
        .to_string()
        .trim()
        .to_string(),
      batch_size: fields.next().unwrap().to_string().trim().parse().unwrap(),
      cron_schedule: fields.next().unwrap().to_string().trim().to_string(),
      updated_at: Timestamp::from_str(
        fields.next().unwrap().to_string().as_str(),
      )
      .unwrap(),
    }
  }
}

impl std::fmt::Display for DataRetentionPolicy {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    write!(
      f,
      "Policy[{}]: {}.{}.{} ({}d, column: {}, batch: {}, cron: {}) updated_at: {}",
      self.id,
      self.database_name,
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
      database_name: row
        .get_datum_by_ordinal(2)
        .expect("Failed to get database_name")
        .value::<String>()
        .expect("Failed to cast database_name to String")
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

#[cfg(any(test, feature = "pg_test"))]
#[pg_schema]
mod tests {
  use super::*;
  use pgrx::prelude::*;

  #[pg_test]
  fn test_from_csv() {
    // Input: 2, db1, public, products, 30, inserted_at, 1000, 0 0 * * *, 2025-07-05 00:14:51.729091
    let csv_input = "2, db1, public, products, 30, inserted_at, 1000, 0 0 * * *, 2025-07-05 00:14:51.729091";

    let policy = DataRetentionPolicy::from_csv(csv_input);
    println!("Policy: {}", policy);

    assert_eq!(policy.id, 2);
    assert_eq!(policy.database_name, "db1");
    assert_eq!(policy.schema_name, "public");
    assert_eq!(policy.table_name, "products");
    assert_eq!(policy.retention_days, 30);
    assert_eq!(policy.timestamp_column_name, "inserted_at");
    assert_eq!(policy.batch_size, 1000);
    assert_eq!(policy.cron_schedule, "0 0 * * *");

    // The timestamp string in the CSV is "2025-07-05 00:14:51.729091"
    // The from_csv function parses this directly into a Timestamp
    // We can verify by converting the timestamp back to a string and comparing
    let timestamp_str = format!("{}", policy.updated_at);
    assert!(timestamp_str.contains("2025-07-05 00:14:51.729091"));
  }
}
