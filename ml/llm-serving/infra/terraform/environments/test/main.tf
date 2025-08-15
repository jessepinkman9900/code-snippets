module "ec2_gpu" {
  source = "../../modules/ec2-gpu"

  environment = var.common_tags.environment
  app_prefix  = var.common_tags.app_prefix
  aws_region  = var.default_aws_region
  ec2_config  = var.ec2_config
}

output "node_public_ip" {
  value = module.ec2_gpu.node_public_ip
}

output "node_private_ip" {
  value = module.ec2_gpu.node_private_ip
}

output "node_username" {
  value = module.ec2_gpu.node_username
}

output "shh_private_key_local_path" {
  value = module.ec2_gpu.shh_private_key_local_path
}

output "shh_public_key_local_path" {
  value = module.ec2_gpu.shh_public_key_local_path
}
