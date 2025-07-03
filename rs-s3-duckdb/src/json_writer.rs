use anyhow::{Context, Result};
use std::fs::File;
use std::io::Write;
use std::path::Path;

pub fn write_json_value_to_file<P>(
  json_value: &serde_json::Value,
  file_path: P,
  pretty: bool,
) -> Result<()>
where
  P: AsRef<Path>,
{
  // Create the file
  let mut file = File::create(&file_path).with_context(|| {
    format!("Failed to create file: {}", file_path.as_ref().display())
  })?;

  // Serialize the data
  let json_string = if pretty {
    serde_json::to_string_pretty(json_value)?
  } else {
    serde_json::to_string(json_value)?
  };

  // Write to the file
  file.write_all(json_string.as_bytes()).with_context(|| {
    format!("Failed to write to file: {}", file_path.as_ref().display())
  })?;

  Ok(())
}
