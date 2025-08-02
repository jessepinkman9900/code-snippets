# required
variable "default_aws_region" {
  type = string
}

# common tags
variable "common_tags" {
  type = object({
    environment = string
    app_prefix  = string
  })
}

variable "rancher_server_config" {
  type = map(object({
    region = string
    # ec2 config
    instance_type    = string
    vpc_id           = string
    public_subnet_id = string
    # installation config
    cert_manager_version       = string
    rancher_helm_repository    = string
    rancher_version            = string
    rancher_kubernetes_version = string
    rancher_admin_password     = string
  }))
}
