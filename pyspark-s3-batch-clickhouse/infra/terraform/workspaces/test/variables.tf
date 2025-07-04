variable "app_prefix" {
  type    = string
  default = "tf"
  description = "for all modules"
}

variable "environment" {
  type    = string
  default = "test"
  description = "for all modules"
}

variable "cloud_provider" {
  type    = string
  default = "aws"
  description = "for clickhouse module"
}

variable "cloud_provider_region" {
  type    = string
  default = "eu-central-1"
  description = "for clickhouse module"
}
