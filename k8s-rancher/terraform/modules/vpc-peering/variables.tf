variable "common_tags" {
  type = object({
    environment = string
    app_prefix  = string
  })
}

# required
variable "vpc_peering_config" {
  type = object({
    requester_vpc_id                  = string
    requester_region                  = string
    requester_cidr_block              = string
    requester_public_route_table_id   = string
    requester_private_route_table_ids = set(string)
    accepter_vpc_id                   = string
    accepter_region                   = string
    accepter_cidr_block               = string
    accepter_public_route_table_id    = string
    accepter_private_route_table_ids  = set(string)
    auto_accept                       = bool
  })
}
