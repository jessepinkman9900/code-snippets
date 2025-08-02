terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "7.3.2"
    }
  }
}

provider "aws" {
  region = var.default_aws_region
}

provider "rancher2" {
  api_url    = var.rancher_api_config.url
  access_key = var.rancher_api_config.access_key
  secret_key = var.rancher_api_config.secret_key
  insecure   = true
}
