provider "aws" {
  region = var.rancher_server_config["me-central-1"].region
}

module "rancher_server" {
  source = "../../../../modules/rancher-server-ec2"

  environment = var.common_tags.environment
  app_prefix  = var.common_tags.app_prefix

  aws_region = var.rancher_server_config["me-central-1"].region
  ec2_config = {
    instance_type    = var.rancher_server_config["me-central-1"].instance_type
    vpc_id           = var.rancher_server_config["me-central-1"].vpc_id
    public_subnet_id = var.rancher_server_config["me-central-1"].public_subnet_id
  }
  rancher_installation_config = {
    cert_manager_version       = var.rancher_server_config["me-central-1"].cert_manager_version
    rancher_helm_repository    = var.rancher_server_config["me-central-1"].rancher_helm_repository
    rancher_version            = var.rancher_server_config["me-central-1"].rancher_version
    rancher_kubernetes_version = var.rancher_server_config["me-central-1"].rancher_kubernetes_version
    rancher_admin_password     = var.rancher_server_config["me-central-1"].rancher_admin_password
  }
}

output "rancher_server_dns" {
  value = module.rancher_server.rancher_server_dns
}
