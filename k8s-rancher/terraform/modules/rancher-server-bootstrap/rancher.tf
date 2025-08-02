
resource "rancher2_bootstrap" "admin" {
  provider = rancher2.bootstrap

  password = var.rancher_server_admin_password

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Rancher server to be ready before bootstrap..."
      timeout 300 bash -c 'until curl -k -s https://${var.rancher_server_dns}/ping; do echo "Waiting for Rancher..."; sleep 10; done'
      echo "Rancher server is ready for bootstrap!"
    EOT
  }
}

resource "rancher2_token" "api_token" {
  depends_on = [rancher2_bootstrap.admin]

  provider = rancher2.admin

  description = "${var.app_prefix}-${var.environment}-api-token"
}
