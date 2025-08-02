module "eks_cluster" {
  source = "../../../../modules/rancher-cluster-create/aws-eks"

  for_each = { for idx, cluster in var.clusters : "${cluster.cluster_id}-${cluster.aws_region}" => cluster }

  common_tags = var.common_tags

  rancher_api_config = var.rancher_api_config

  aws_config = var.aws_config

  cluster = each.value
}
