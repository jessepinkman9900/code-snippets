data "aws_availability_zones" "available" {
  region = var.aws_region
  state = "available"
}

locals {
  az_count = length(data.aws_availability_zones.available.names)

  # public subnets - 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24
  public_subnet_cidrs = [
    for i in range(local.az_count): cidrsubnet(var.vpc_cidr_block, 8, i)
  ]

  # private subnets - 10.0.100.0/24, 10.0.101.0/24, 10.0.102.0/24
  private_subnet_cidrs = [
    for i in range(local.az_count): cidrsubnet(var.vpc_cidr_block, 8, i + 100)
  ]
}

# required
variable "aws_region" {
  type = string
}

# required
variable "environment" {
  type = string
}

# required
variable "app_prefix" {
  type = string
}

# required
variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

# optional
variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = false
  description = "If true, only one NAT gateway will be created for all private subnets to use to connect to the internet"
}
