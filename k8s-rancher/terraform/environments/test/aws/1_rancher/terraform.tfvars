default_aws_region = "sa-east-1"

common_tags = {
  environment = "test"
  app_prefix  = "rancher"
}

rancher_server_config = {
  "me-central-1" = {
    region                     = "me-south-1"
    instance_type              = "t3.medium"
    rancher_admin_password     = "adminadminadmin"
    vpc_id                     = "vpc-01f20ddd8ec2e0fea"
    public_subnet_id           = "subnet-0fe72e00a06a5f77a"
    cert_manager_version       = "1.11.0"
    rancher_helm_repository    = "https://releases.rancher.com/server-charts/latest"
    rancher_version            = "2.11.3"
    rancher_kubernetes_version = "v1.31.9+k3s1"
  }
}
