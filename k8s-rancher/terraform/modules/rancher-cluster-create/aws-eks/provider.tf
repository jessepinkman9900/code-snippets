terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "7.3.2"
    }
  }
}
