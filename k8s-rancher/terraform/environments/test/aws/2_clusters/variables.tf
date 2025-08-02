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

# required
variable "rancher_api_config" {
  type = object({
    url        = string
    access_key = string
    secret_key = string
  })
  sensitive = true
}

# required
variable "aws_config" {
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
  sensitive = true
}

# required
variable "clusters" {
  type = list(object({
    cluster_id         = string
    kubernetes_version = string
    aws_region         = string
    public_subnet_ids  = list(string)
    node_groups = list(object({
      name          = string
      instance_type = string
      desired_size  = number
      max_size      = number
    }))
    timeouts = object({
      create = string
      update = string
      delete = string
    })
    tags = map(string)
  }))
}
