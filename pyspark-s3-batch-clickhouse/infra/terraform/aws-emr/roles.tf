

resource "aws_iam_role" "emr_studio_role" {
  name               = "${var.app_prefix}-${var.environment}-emr-studio-role"
  assume_role_policy = data.aws_iam_policy_document.emr_studio_role_policy_doc.json
}

resource "aws_iam_role_policy" "emr_studio_policy" {
  name   = "${var.app_prefix}-${var.environment}-emr-studio-policy"
  role   = aws_iam_role.emr_studio_role.id
  policy = data.aws_iam_policy_document.emr_studio_policy_doc.json
}

resource "aws_iam_role" "emr_serverless_role" {
  name               = "${var.app_prefix}-${var.environment}-emr-serverless-role"
  assume_role_policy = data.aws_iam_policy_document.emr_serverless_trust_policy_doc.json
}

resource "aws_iam_role_policy" "emr_serverless_policy" {
  name   = "${var.app_prefix}-${var.environment}-emr-serverless-policy"
  role   = aws_iam_role.emr_serverless_role.id
  policy = data.aws_iam_policy_document.emr_serverless_s3_glue_policy_doc.json
}
