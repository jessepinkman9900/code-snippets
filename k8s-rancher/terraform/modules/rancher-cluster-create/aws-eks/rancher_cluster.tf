resource "rancher2_cloud_credential" "aws" {
  name = "${var.common_tags.app_prefix}-${var.common_tags.environment}-aws"

  amazonec2_credential_config {
    access_key = var.aws_config.access_key_id
    secret_key = var.aws_config.secret_access_key
  }
}

resource "rancher2_cluster" "eks" {
  name = "${var.common_tags.app_prefix}-${var.common_tags.environment}-eks-${var.cluster.cluster_id}-${var.cluster.aws_region}"

  eks_config_v2 {
    cloud_credential_id = rancher2_cloud_credential.aws.id
    region = var.cluster.aws_region
    kubernetes_version = var.cluster.kubernetes_version
    logging_types = ["api", "audit"]
    subnets = var.cluster.public_subnet_ids
    dynamic "node_groups" {
      for_each = toset(var.cluster.node_groups)
      content {
        name = node_groups.value.name
        instance_type = node_groups.value.instance_type
        desired_size = node_groups.value.desired_size
        max_size = node_groups.value.max_size
      }
    }
    private_access = true
    public_access = true
    tags = var.cluster.tags
  }
  timeouts {
    create = var.cluster.timeouts.create
    update = var.cluster.timeouts.update
    delete = var.cluster.timeouts.delete
  }
}

output "cluster_id" {
  value = rancher2_cluster.eks.id
}
