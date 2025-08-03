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
variable "network_config" {
  type = object({
    enable_vpc_peering = bool,
    regions = map(object({
      region             = string
      vpc_cidr_block     = string
      enable_nat_gateway = bool
      single_nat_gateway = bool
    }))
  })
}
