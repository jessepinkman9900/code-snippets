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
variable "ec2_config" {
  type = object({
    instance_type = string
  })
}
