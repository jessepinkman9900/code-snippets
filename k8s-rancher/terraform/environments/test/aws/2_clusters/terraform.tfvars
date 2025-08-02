default_aws_region = "me-central-1"

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
      "subnet-0e07477623a3dfea8",
      "subnet-0554f1ec05641abe4",
      "subnet-0ae426dad47807194",
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
  },
  {
    cluster_id         = "001"
    kubernetes_version = "1.33"
    aws_region         = "me-south-1"
    public_subnet_ids = [
      "subnet-021af243e2ca71251",
      "subnet-03137d2e4a83e18b2",
      "subnet-03aeaed9232815b74",
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
  }
]
