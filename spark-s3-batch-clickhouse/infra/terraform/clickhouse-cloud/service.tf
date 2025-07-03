# Generate a random password for ClickHouse service
resource "random_password" "clickhouse_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "clickhouse_service" "service" {
  name = "${var.app_prefix}-${var.environment}-clickhouse"
  cloud_provider = var.cloud_provider
  region = var.cloud_provider_region
  ip_access = [{
    source = "0.0.0.0/0"
    description = "Allow access from anywhere"
  }]

  num_replicas = 1
  min_replica_memory_gb = 8
  max_replica_memory_gb = 8
  idle_scaling = true
  idle_timeout_minutes = 15
  password = random_password.clickhouse_password.result
}

output "clickhouse_password" {
  value     = random_password.clickhouse_password.result
  sensitive = true
  description = "The password for the ClickHouse service"
}
