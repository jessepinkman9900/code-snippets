provider "aws" {
  region = var.default_aws_region
}

module "network" {
  for_each = var.network_config.regions

  source = "../../../../modules/network/aws"

  environment = var.common_tags.environment
  app_prefix  = var.common_tags.app_prefix

  aws_region         = each.value.region
  vpc_cidr_block     = each.value.vpc_cidr_block
  enable_nat_gateway = each.value.enable_nat_gateway
  single_nat_gateway = each.value.single_nat_gateway
}

output "network_creation_summary" {
  value = {
    for region_key, network in module.network : region_key => {
      region                  = var.network_config.regions[region_key].region
      vpc_id                  = network.vpc_id
      vpc_cidr_block          = network.vpc_cidr_block
      availability_zones      = network.availability_zones
      public_subnet_ids       = network.public_subnet_ids
      private_subnet_ids      = network.private_subnet_ids
      public_subnet_cidrs     = network.public_subnet_cidrs
      private_subnet_cidrs    = network.private_subnet_cidrs
      internet_gateway_id     = network.internet_gateway_id
      nat_gateway_ids         = network.nat_gateway_ids
      public_route_table_id   = network.public_route_table_id
      private_route_table_ids = network.private_route_table_ids
    }
  }
}

# local calculation for VPC peering
locals {
  regions = keys(var.network_config.regions)

  # Create unique pairs to avoid duplicate peering connections
  # Sort region keys to ensure consistent ordering
  sorted_regions = sort(local.regions)

  peering_pairs = flatten([
    for i, region_a in local.sorted_regions : [
      for j, region_b in local.sorted_regions : {
        key                               = "${region_a}-${region_b}"
        requester_key                     = region_a
        accepter_key                      = region_b
        requester_region                  = var.network_config.regions[region_a].region
        accepter_region                   = var.network_config.regions[region_b].region
        requester_vpc_id                  = module.network[region_a].vpc_id
        accepter_vpc_id                   = module.network[region_b].vpc_id
        requester_cidr_block              = module.network[region_a].vpc_cidr_block
        accepter_cidr_block               = module.network[region_b].vpc_cidr_block
        requester_private_route_table_ids = toset(module.network[region_a].private_route_table_ids)
        requester_public_route_table_id   = module.network[region_a].public_route_table_id
        accepter_private_route_table_ids  = toset(module.network[region_b].private_route_table_ids)
        accepter_public_route_table_id    = module.network[region_b].public_route_table_id
      }
      if i < j # Only create peering for unique pairs (avoid duplicates and self-peering)
    ]
  ])

  peering_map = {
    for pair in local.peering_pairs : pair.key => pair
  }
}

# create vpc peering connections between all regions if enabled
module "vpc_peering" {
  depends_on = [module.network]
  source     = "../../../../modules/vpc-peering"

  for_each = var.network_config.enable_vpc_peering ? local.peering_map : {}

  common_tags = var.common_tags

  vpc_peering_config = {
    requester_region                  = each.value.requester_region
    requester_vpc_id                  = each.value.requester_vpc_id
    requester_cidr_block              = each.value.requester_cidr_block
    accepter_region                   = each.value.accepter_region
    accepter_vpc_id                   = each.value.accepter_vpc_id
    accepter_cidr_block               = each.value.accepter_cidr_block
    requester_private_route_table_ids = toset(each.value.requester_private_route_table_ids)
    requester_public_route_table_id   = each.value.requester_public_route_table_id
    accepter_private_route_table_ids  = toset(each.value.accepter_private_route_table_ids)
    accepter_public_route_table_id    = each.value.accepter_public_route_table_id
    # applied only for same region peering
    auto_accept = true
  }
}

output "vpc_peering_summary" {
  value = var.network_config.enable_vpc_peering ? {
    for peering_key, peering in module.vpc_peering : peering_key => {
      vpc_peering_connection_id = peering.peer_connection_id
      status                    = peering.peer_connection_status
      requester_region          = local.peering_map[peering_key].requester_region
      requester_vpc_id          = local.peering_map[peering_key].requester_vpc_id
      requester_cidr_block      = local.peering_map[peering_key].requester_cidr_block
      accepter_region           = local.peering_map[peering_key].accepter_region
      accepter_vpc_id           = local.peering_map[peering_key].accepter_vpc_id
      accepter_cidr_block       = local.peering_map[peering_key].accepter_cidr_block
    }
  } : {}
}
