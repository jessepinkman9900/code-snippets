use bytes::Bytes;
use futures::StreamExt; // Import StreamExt trait for next()
use rdkafka::config::ClientConfig;
use rdkafka::producer::FutureProducer;
use rdkafka::producer::FutureRecord;
use std::pin::Pin;
use std::time::Duration;
use tokio_postgres::CopyOutStream;
use tokio_postgres::Error;

#[derive(Debug)]
pub struct KafkaConfig {
  pub bootstrap_servers: String,
}

pub fn create_client(config: KafkaConfig) -> FutureProducer {
  let producer = ClientConfig::new()
    .set("bootstrap.servers", &config.bootstrap_servers)
    // .set("acks", "all")
    // .set("message.max.bytes", "1000000")
    .set("batch.num.messages", "10000")
    // .set("linger.ms", "20")
    .set("compression.type", "lz4")
    .create()
    .expect("Failed to create producer");
  producer
}

pub async fn publish_copy_out_stream(
  producer: &FutureProducer,
  mut stream: Pin<Box<CopyOutStream>>,
) -> Result<Option<String>, Error> {
  let batch_size = 5000; // Increased batch size for better throughput
  let mut total_processed = 0;

  // Create a channel for processing stream data in parallel
  let (tx, mut rx) = tokio::sync::mpsc::channel::<Bytes>(1000); // Buffer up to 1000 messages

  // Spawn a task to read from the stream
  let stream_task = tokio::spawn(async move {
    let mut last_row_bytes = Bytes::new();
    let mut result = Ok(None);

    while let Some(row_result) = stream.next().await {
      match row_result {
        Ok(bytes) => {
          // Keep track of the last row
          last_row_bytes = bytes.clone();

          // Send the bytes through the channel for processing
          if tx.send(bytes).await.is_err() {
            // Channel closed, receiver dropped
            break;
          }
        }
        Err(e) => {
          log::error!("Error reading row: {}", e);
          result = Err(e);
          break;
        }
      }
    }

    // Convert the last row to a string if we have one
    if !last_row_bytes.is_empty() {
      let last_row_str = String::from_utf8_lossy(&last_row_bytes).to_string();
      if result.is_ok() {
        result = Ok(Some(last_row_str));
      }
    }

    result
  });

  // Process batches in parallel while the stream is being read
  let mut batch_payloads = Vec::with_capacity(batch_size);
  let mut processing_complete = false;

  while !processing_complete {
    // Collect a batch of messages
    while batch_payloads.len() < batch_size {
      match tokio::time::timeout(Duration::from_millis(100), rx.recv()).await {
        Ok(Some(bytes)) => {
          // Process bytes and add to batch
          let payload = build_payload_from_bytes(&bytes);
          batch_payloads.push(payload);
        }
        Ok(None) => {
          // Channel closed, no more data
          processing_complete = true;
          break;
        }
        Err(_) => {
          // Timeout, process what we have so far if not empty
          if !batch_payloads.is_empty() {
            break;
          }

          // Check if stream task is done
          if stream_task.is_finished() {
            processing_complete = true;
            break;
          }
        }
      }
    }

    // Send the batch if we have any messages
    if !batch_payloads.is_empty() {
      send_batch_to_kafka(producer, &batch_payloads).await;
      total_processed += batch_payloads.len();
      log::info!("Processed {} records", total_processed);
      batch_payloads.clear();
    }
  }

  // Wait for the stream task to complete and get the result
  match stream_task.await {
    Ok(result) => {
      log::info!("Processed {} records total", total_processed);
      result
    }
    Err(e) => {
      log::error!("Stream processing task panicked: {}", e);
      Ok(None)
    }
  }
}

/// Send a batch of messages to Kafka in parallel using multiple tokio tasks
async fn send_batch_to_kafka(producer: &FutureProducer, payloads: &[String]) {
  // Process chunks of the stream in parallel
  let chunk_size = 5000;
  let mut tasks = Vec::new();

  // Split the payloads into chunks and process each chunk in a separate task
  for chunk in payloads.chunks(chunk_size) {
    let producer_clone = producer.clone(); // FutureProducer implements Clone
    let chunk_data = chunk.to_vec(); // Clone the chunk data for the task

    // Spawn a new task to process this chunk
    let task = tokio::spawn(async move { send_chunk_to_kafka(&producer_clone, &chunk_data).await });

    tasks.push(task);
  }

  // Wait for all tasks to complete
  for task in tasks {
    if let Err(e) = task.await {
      log::error!("Task panicked: {}", e);
    }
  }

  log::debug!(
    "Completed sending {} messages in {} chunks",
    payloads.len(),
    (payloads.len() as f64 / chunk_size as f64).ceil() as usize
  );
}

// Removed unused function in favor of build_payload_from_bytes

/// Process a chunk of messages and send them to Kafka
/// This function is called by each spawned task
async fn send_chunk_to_kafka(producer: &FutureProducer, payloads: &[String]) {
  // Create a vector to hold all the futures
  let mut futures = Vec::with_capacity(payloads.len());

  // Start sending all messages in parallel
  for payload in payloads {
    let future = producer.send(
      FutureRecord::to("postgres-cdc")
        .payload(payload)
        .key("some_key"),
      Duration::from_secs(0),
    );
    futures.push(future);
  }

  // Wait for all sends to complete
  let mut success_count = 0;
  let mut error_count = 0;

  for future in futures {
    match future.await {
      Ok(_) => {
        success_count += 1;
      }
      Err(e) => {
        // Log the error but continue with other messages
        log::error!("Failed to send message to Kafka: {}", e.0);
        error_count += 1;
      }
    }
  }

  log::debug!(
    "Chunk complete: {} messages sent successfully, {} errors",
    success_count,
    error_count
  );
}

/// Build a payload directly from bytes to minimize unnecessary conversions
fn build_payload_from_bytes(bytes: &impl AsRef<[u8]>) -> String {
  // Try to parse directly from bytes using from_slice
  // This avoids an intermediate string allocation
  let bytes_ref = bytes.as_ref();
  let row_value = serde_json::from_slice::<serde_json::Value>(bytes_ref).unwrap_or_else(|_| {
    // Fall back to string if not valid JSON
    let s = String::from_utf8_lossy(bytes_ref);
    serde_json::Value::String(s.to_string())
  });

  let json = serde_json::json!({
    "row": row_value,
    "timestamp": chrono::Utc::now().to_rfc3339(),
  });

  // Allocate the result string with capacity to avoid reallocations
  let mut result = String::with_capacity(bytes.as_ref().len() + 100); // Add extra space for timestamp
  serde_json::to_writer(unsafe { result.as_mut_vec() }, &json).expect("Failed to serialize JSON");

  result
}
