default_aws_region = "eu-west-3"

common_tags = {
  environment = "test"
  app_prefix  = "llm-serving"
}

ec2_config = {
  instance_type = "g6.xlarge"
}
