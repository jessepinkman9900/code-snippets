resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  chart            = "https://charts.jetstack.io/charts/cert-manager-v${var.rancher_installation_config.cert_manager_version}.tgz"
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]
}

resource "helm_release" "rancher_server" {
  depends_on = [
    helm_release.cert_manager,
  ]
  name             = "rancher"
  chart            = "${var.rancher_installation_config.rancher_helm_repository}/rancher-${var.rancher_installation_config.rancher_version}.tgz"
  namespace        = "cattle-system"
  create_namespace = true
  wait             = true

  set = [
    {
      name  = "hostname"
      value = join(".", ["rancher", aws_instance.rancher_server.public_ip, "sslip.io"])
    },
    {
      name  = "replicas"
      value = 1
    },
    {
      name  = "bootstrapPassword"
      value = var.rancher_installation_config.rancher_admin_password
    }
  ]
}

output "rancher_server_dns" {
  value = join(".", ["rancher", aws_instance.rancher_server.public_ip, "sslip.io"])
}
