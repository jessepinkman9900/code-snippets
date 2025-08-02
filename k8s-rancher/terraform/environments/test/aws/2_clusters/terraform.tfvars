default_aws_region = "sa-east-1"

common_tags = {
  environment = "test"
  app_prefix  = "rancher"
}

clusters = [
  {
    cluster_id         = "001"
    kubernetes_version = "1.33"
    aws_region         = "me-central-1"
    public_subnet_ids = [
      "subnet-06d889b4a8b36572e",
      "subnet-0ab125a1e2fd525c0",
      "subnet-00718d95d9526d8cd"
    ]
    node_groups = [
      {
        name          = "ng-001"
        instance_type = "t3.small"
        desired_size  = 2
        max_size      = 3
      }
    ]
    timeouts = {
      create = "30m"
      update = "30m"
      delete = "30m"
    }
    tags = {
      environment = "test"
      app_prefix  = "rancher"
    }
    labels = {
      environment = "test"
      "provider.cattle.io" = "eks"
    }
  },
  {
    cluster_id         = "001"
    kubernetes_version = "1.33"
    aws_region         = "me-south-1"
    public_subnet_ids = [
      "subnet-0fe72e00a06a5f77a",
      "subnet-00816acc61cf9572d",
      "subnet-0231b9456f8623454"
    ]
    node_groups = [
      {
        name          = "ng-001"
        instance_type = "t3.small"
        desired_size  = 2
        max_size      = 3
      }
    ]
    timeouts = {
      create = "30m"
      update = "30m"
      delete = "30m"
    }
    tags = {
      environment = "test"
      app_prefix  = "rancher"
    }
    labels = {
      environment = "test"
      "provider.cattle.io" = "eks"
    }
  }
]
