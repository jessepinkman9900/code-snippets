use anyhow::{Context, Result};
use aws_sdk_s3::config::Region;
use aws_sdk_s3::Client;
use bytes::Bytes;

pub async fn create_client() -> Result<Client> {
  // check env var
  if std::env::var("AWS_ACCESS_KEY_ID").is_err()
    || std::env::var("AWS_SECRET_ACCESS_KEY").is_err()
  {
    log::error!("AWS credentials not found in environment variables.");
    log::error!("Please set the following environment variables:");
    log::error!("  export AWS_ACCESS_KEY_ID=your_access_key");
    log::error!("  export AWS_SECRET_ACCESS_KEY=your_secret_key");
    return Err(anyhow::anyhow!("Missing AWS credentials"));
  }

  // define bucket & region
  let bucket = "hl-mainnet-node-data";
  let region = Region::new("ap-northeast-1");

  log::info!("Using S3 bucket: {} in region: {}", bucket, region.as_ref());

  // create config
  let config = aws_config::from_env().region(region).load().await;

  Ok(Client::new(&config))
}

pub async fn get_object(
  client: &Client,
  bucket: &str,
  key: &str,
) -> Result<Bytes> {
  let resp = client
    .get_object()
    .bucket(bucket)
    .key(key)
    .request_payer(aws_sdk_s3::types::RequestPayer::Requester) // Enable requester pays
    .send()
    .await
    .context("Failed to get object from S3")?;

  let data = resp
    .body
    .collect()
    .await
    .context("Failed to read object bytes")?;
  let data = data.into_bytes();

  Ok(data)
}
