
resource "ssh_resource" "install_k3s" {
  host        = aws_instance.rancher_server.public_ip
  user        = local.node_username
  private_key = tls_private_key.global_key.private_key_pem

  commands = [
    "bash -c 'curl https://get.k3s.io | INSTALL_K3S_EXEC=\"server --node-external-ip ${aws_instance.rancher_server.public_ip} --node-ip ${aws_instance.rancher_server.private_ip}\" INSTALL_K3S_VERSION=${var.rancher_installation_config.rancher_kubernetes_version} sh -'"
  ]
}

resource "ssh_resource" "retrieve_config" {
  depends_on = [
    ssh_resource.install_k3s,
    ssh_resource.retrieve_config
  ]
  host        = aws_instance.rancher_server.public_ip
  user        = local.node_username
  private_key = tls_private_key.global_key.private_key_pem

  commands = [
    "sudo sed \"s/127.0.0.1/${aws_instance.rancher_server.public_ip}/g\" /etc/rancher/k3s/k3s.yaml"
  ]
}

resource "local_file" "kube_config_server_yaml" {
  filename = format("%s/.output/${var.environment}/rancher_node/%s", path.root, "kube_config_server.yaml")
  content  = ssh_resource.retrieve_config.result
}
