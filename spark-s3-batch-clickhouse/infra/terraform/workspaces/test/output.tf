output "clickhouse_password" {
  value     = module.clickhouse_service.clickhouse_password
  sensitive = true
}
