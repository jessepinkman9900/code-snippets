
module "emr_studio_serverless_application" {
  source = "../../aws-emr"

  app_prefix = var.app_prefix
  environment  = var.environment
}

module "clickhouse_service" {
  source = "../../clickhouse-cloud"

  app_prefix = var.app_prefix
  environment  = var.environment
  cloud_provider = var.cloud_provider
  cloud_provider_region = var.cloud_provider_region
}
