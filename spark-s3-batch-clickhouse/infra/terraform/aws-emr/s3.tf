
resource "aws_s3_bucket" "emr_studio_bucket" {
  bucket = "${var.app_prefix}-${var.environment}-emr-studio-bucket"
}
