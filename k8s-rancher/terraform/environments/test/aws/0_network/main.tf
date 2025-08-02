provider "aws" {
  region = var.default_aws_region
}

module "network" {
  for_each = var.network_config

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
      region                  = var.network_config[region_key].region
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
