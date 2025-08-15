locals {
  node_username = "ubuntu"
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
variable "aws_region" {
  type = string
}

# required
variable "ec2_config" {
  type = object({
    instance_type = string
  })
}
