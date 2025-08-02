default_aws_region = "sa-east-1"

common_tags = {
  environment = "test"
  app_prefix  = "rancher"
}

network_config = {
  "me-south-1" = {
    region             = "me-south-1"
    vpc_cidr_block     = "10.0.0.0/16"
    enable_nat_gateway = true
    single_nat_gateway = false
  }
  "me-central-1" = {
    region             = "me-central-1"
    vpc_cidr_block     = "10.1.0.0/16"
    enable_nat_gateway = true
    single_nat_gateway = false
  }
}
