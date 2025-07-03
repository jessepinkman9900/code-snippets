use anyhow::{Context, Result};
use bytes::Bytes;
use lz4::Decoder;
use rmpv::Value;
use serde_json::Value as JsonValue;
use std::io::Read;

pub fn decompress_unpack_file(data: &Bytes) -> Result<JsonValue> {
  // lz4 decompress
  let decompressed_data =
    decompress_lz4(&data).context("Failed to decompress LZ4 data")?;
  log::info!("Decompressed size: {} bytes", decompressed_data.len());

  // unpack rmp
  let unpacked_data = parse_messagepack(&decompressed_data)
    .context("Failed to unpack MessagePack data")?;
  log::info!("Successfully unpacked MessagePack data");

  // convert to json
  let json_value = value_to_json(&unpacked_data);
  log::info!("Successfully converted to JSON");

  Ok(json_value)
}

fn decompress_lz4(compressed: &Bytes) -> Result<Vec<u8>> {
  let mut decoder = Decoder::new(compressed.as_ref())?;
  let mut decompressed = Vec::new();
  decoder.read_to_end(&mut decompressed)?;
  Ok(decompressed)
}

fn parse_messagepack(data: &[u8]) -> Result<Value> {
  let mut cursor = std::io::Cursor::new(data);
  let value = rmpv::decode::read_value(&mut cursor)
    .context("Failed to decode MessagePack data")?;
  Ok(value)
}

fn value_to_json(value: &Value) -> JsonValue {
  match value {
    Value::Nil => JsonValue::Null,
    Value::Boolean(b) => JsonValue::Bool(*b),
    Value::Integer(i) => {
      if let Some(i) = i.as_i64() {
        JsonValue::Number(serde_json::Number::from(i))
      } else {
        JsonValue::String(i.to_string())
      }
    }
    Value::F32(f) => JsonValue::Number(
      serde_json::Number::from_f64(*f as f64)
        .unwrap_or(serde_json::Number::from(0)),
    ),
    Value::F64(f) => JsonValue::Number(
      serde_json::Number::from_f64(*f).unwrap_or(serde_json::Number::from(0)),
    ),
    Value::String(s) => {
      // Remove any surrounding quotes to prevent double escaping
      let s_str = s.to_string();
      let cleaned = s_str.trim_matches('"');
      JsonValue::String(cleaned.to_string())
    }
    Value::Binary(b) => {
      JsonValue::String(format!("<binary data of length {}>", b.len()))
    }
    Value::Array(arr) => {
      let values: Vec<JsonValue> = arr.iter().map(value_to_json).collect();
      JsonValue::Array(values)
    }
    Value::Map(m) => {
      let mut map = serde_json::Map::new();
      for (k, v) in m {
        let key = match k {
          Value::String(s) => {
            // Remove any surrounding quotes from keys
            let s_str = s.to_string();
            s_str.trim_matches('"').to_string()
          }
          _ => format!("{:?}", k),
        };
        map.insert(key, value_to_json(v));
      }
      JsonValue::Object(map)
    }
    Value::Ext(_, _) => JsonValue::String("<extension data>".to_string()),
  }
}
