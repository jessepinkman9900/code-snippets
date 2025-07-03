
resource "aws_emr_studio" "emr_studio" {
  name                = "${var.app_prefix}-${var.environment}-emr-studio"
  auth_mode           = "IAM"
  default_s3_location = "s3://${aws_s3_bucket.emr_studio_bucket.bucket}/emr-studio"

  vpc_id     = aws_vpc.emr_vpc.id
  subnet_ids = [aws_subnet.emr_vpc_public_subnet1.id]

  engine_security_group_id    = aws_security_group.emr_security_group.id
  workspace_security_group_id = aws_security_group.emr_security_group.id

  service_role = aws_iam_role.emr_studio_role.arn
}

resource "aws_emrserverless_application" "emr_serverless_application" {
  name          = "${var.app_prefix}-${var.environment}-emr-serverless-application"
  type          = "spark"
  release_label = "emr-7.9.0"
  architecture  = "X86_64"

  auto_start_configuration {
    enabled = true
  }

  auto_stop_configuration {
    enabled              = true
    idle_timeout_minutes = 10
  }

  interactive_configuration {
    studio_enabled = true
  }

  maximum_capacity {
    cpu    = "16 vCPU"
    memory = "128 GB"
    disk   = "200 GB"
  }

  initial_capacity {
    initial_capacity_type = "Driver"
    initial_capacity_config {
      worker_count = 1
      worker_configuration {
        cpu    = "1 vCPU"
        memory = "2 GB"
        disk   = "20 GB"
      }
    }
  }

  initial_capacity {
    initial_capacity_type = "Executor"
    initial_capacity_config {
      worker_count = 2
      worker_configuration {
        cpu    = "1 vCPU"
        memory = "2 GB"
        disk   = "20 GB"
      }
    }
  }

  # TODO: Add network configuration
  # network_configuration {

  # }

  tags = {
    environment = var.environment
  }

}
