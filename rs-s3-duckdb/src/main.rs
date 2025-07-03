use anyhow::{Context, Result};

mod duckdb_service;
mod file_parser_service;
mod json_writer;
mod s3_service;

#[tokio::main]
async fn main() -> Result<()> {
  env_logger::init();

  let bucket = "hl-mainnet-node-data";
  let key = "explorer_blocks/0/0/98400.rmp.lz4";

  // fetch from s3
  let client = s3_service::create_client().await.unwrap();
  log::info!("Fetching file: {}", key);
  let data = s3_service::get_object(&client, bucket, key).await.unwrap();
  let json_value = file_parser_service::decompress_unpack_file(&data)
    .context("Failed to decompress and unpack file")?;
  log::info!("Successfully parsed MessagePack structure to JSON");

  // Write the JSON value to a file
  let block_number = key.split("/").last().unwrap().split(".").next().unwrap();
  let output_path = format!("block_{}.json", block_number);
  json_writer::write_json_value_to_file(&json_value, &output_path, true)
    .context("Failed to write JSON to file")?;
  log::info!("Successfully wrote JSON to {}", &output_path);

  // insert into duckdb
  let conn = duckdb_service::create_connection();
  let sql = "SELECT * FROM information_schema.schemata;";
  let mut stmt = conn.prepare(sql)?;
  let mut rows = stmt.query([])?;

  // Process query results
  while let Some(row) = rows.next()? {
    // Get schema_name from the row (assuming it's the second column)
    let _ = row.get::<_, String>(0).and_then(|catalog_name| {
      row.get::<_, String>(1).map(|schema_name| {
        log::info!("Catalog: {}, Schema: {}", catalog_name, schema_name)
      })
    });
  }
  // todo: normalise & insert into duckdb
  Ok(())
}
