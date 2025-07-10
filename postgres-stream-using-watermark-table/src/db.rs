use std::pin::Pin;

use diesel::prelude::*;
use diesel_migrations::{EmbeddedMigrations, MigrationHarness, embed_migrations};
use tokio_postgres::{Client, CopyOutStream, Error, NoTls};

const MIGRATIONS: EmbeddedMigrations = embed_migrations!("migrations");

#[derive(Debug)]
pub struct PostgresConfig {
  pub connection_string: String,
}

pub fn setup_watermark_table(config: &PostgresConfig) {
  let mut connection =
    PgConnection::establish(&config.connection_string).expect("Error connecting to database");

  // run pending migration
  connection
    .run_pending_migrations(MIGRATIONS)
    .expect("Error running migrations");
  log::info!("Migrations run successfully");
}

pub async fn create_client(config: &PostgresConfig) -> Client {
  let (client, connection) = tokio_postgres::connect(&config.connection_string, NoTls)
    .await
    .expect("Error connecting to database");

  // connection object perf comms w db so spawn into own task
  tokio::spawn(async move {
    if let Err(e) = connection.await {
      eprintln!("Connection error: {}", e);
    }
  });

  client
}

/// Get a COPY OUT stream from PostgreSQL with optimized settings for high throughput
pub async fn copy_table_stream(
  client: &Client,
  table_name: &str,
) -> Result<Pin<Box<CopyOutStream>>, Error> {
  // Increase batch size for better throughput
  let batch_size = 50000;

  // Set up client for optimal streaming performance
  client.execute("SET statement_timeout = 0", &[]).await?; // No timeout
  client
    .execute("SET client_min_messages = 'warning'", &[])
    .await?; // Reduce log noise
  client.execute("SET work_mem = '256MB'", &[]).await?; // More memory for sorting
  client.execute("SET temp_buffers = '256MB'", &[]).await?; // More memory for temp tables

  // Use binary format for better performance
  let statement = format!(
    "COPY (SELECT row_to_json(row) FROM {} row LIMIT {}) TO STDOUT BINARY",
    table_name, batch_size
  );

  // Uncomment to use text format instead
  // let statement = format!(
  //   "COPY (SELECT row_to_json(row) FROM {} row LIMIT {}) TO STDOUT",
  //   table_name, batch_size
  // );

  log::info!(
    "Starting COPY OUT stream for {} with batch size {}",
    table_name,
    batch_size
  );

  // Get the copy out stream with larger buffer sizes
  let copy_out_stream = client.copy_out(&statement).await?;

  // Process each chunk from the stream
  let stream = Box::pin(copy_out_stream);

  Ok(stream)
}

/// Updates the watermark table with the current timestamp for the given table
/// This helps track which records have been processed already
pub async fn update_watermark(client: &Client, table_name: &str) -> Result<(), Error> {
  // Insert or update the watermark for this table
  let statement = format!(
    "INSERT INTO stream_watermark (table_name, last_processed_at) 
     VALUES ('{}', NOW()) 
     ON CONFLICT (table_name) 
     DO UPDATE SET last_processed_at = NOW()",
    table_name
  );

  client.execute(&statement, &[]).await?;
  log::info!("Updated watermark for table: {}", table_name);

  Ok(())
}
