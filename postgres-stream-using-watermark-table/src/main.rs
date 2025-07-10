use std::time::Duration;

use rdkafka::producer::FutureRecord;

mod db;
mod kafka;

#[tokio::main]
async fn main() {
  env_logger::init();
  log::info!("Starting application");
  // configs
  let postgres_config = db::PostgresConfig {
    connection_string: "postgres://postgres:postgres@localhost:5432/postgres".to_string(),
  };
  let kafka_config = kafka::KafkaConfig {
    bootstrap_servers: "localhost:9094".to_string(),
  };
  // setup watermark table
  db::setup_watermark_table(&postgres_config);
  // parse config
  // create async pgclient
  let client = db::create_client(&postgres_config).await;
  // create kafka producer
  let producer = kafka::create_client(kafka_config);
  // run streaming
  let stream = db::copy_table_stream(&client, "public.products")
    .await
    .expect("Error running query");
  let status = kafka::publish_copy_out_stream(&producer, stream).await;

  match &status {
    Ok(Some(last_row)) => {
      log::info!("Successfully processed stream with last row: {}", last_row);
      // Update watermark with the last processed row
      let watermark_update_status = db::update_watermark(&client, "public.products").await;
      log::debug!("Watermark update status: {:?}", watermark_update_status);
    }
    Ok(None) => {
      log::info!("No rows were processed in the stream");
    }
    Err(e) => {
      log::error!("Error processing stream: {}", e);
    }
  }

  log::debug!("Stream processing status: {:?}", status);
  // test kafka producer
  // let delivery_status = producer
  //   .send(
  //     FutureRecord::to("postgres-cdc").key("test").payload("test"),
  //     Duration::from_secs(0),
  //   )
  //   .await;
  // log::debug!("Delivery status: {:?}", delivery_status);

  // test postgres client
  // let rows = client.query("SELECT count(*) FROM public.stream_watermark", &[]).await.expect("Error running query");

  // for row in rows {
  //     log::info!("{:?}", row);
  //     let count: i64 = row.get(0);
  //     log::info!("Count: {}", count);
  // }
}
