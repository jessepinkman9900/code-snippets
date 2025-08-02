terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = "7.3.2"
    }
  }
}

provider "rancher2" {
  alias     = "bootstrap"
  api_url   = "https://${var.rancher_server_dns}"
  bootstrap = true
  insecure  = true
}

provider "rancher2" {
  alias     = "admin"
  api_url   = "https://${var.rancher_server_dns}"
  token_key = rancher2_bootstrap.admin.token
  insecure  = true
}
