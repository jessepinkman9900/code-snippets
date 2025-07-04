variable "environment" {
  type    = string
  default = "test"
}

variable "app_prefix" {
  type    = string
  default = "tf"
}

variable "cloud_provider" {
  type    = string
  default = "aws"
}

variable "cloud_provider_region" {
  type    = string
  default = "eu-central-1"
}
