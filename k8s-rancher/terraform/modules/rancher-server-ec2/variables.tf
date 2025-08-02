locals {
  node_username = "ec2-user"
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
    instance_type    = string
    vpc_id           = string
    public_subnet_id = string
  })
}

# required
variable "rancher_installation_config" {
  type = object({
    cert_manager_version       = string
    rancher_helm_repository    = string
    rancher_version            = string
    rancher_kubernetes_version = string
    rancher_admin_password     = string
  })
}
