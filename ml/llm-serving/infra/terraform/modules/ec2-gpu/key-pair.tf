resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "ssh_private_key_pem" {
  filename        = "${path.root}/.output/${var.environment}/gpu_node/keys/id_rsa"
  content         = tls_private_key.global_key.private_key_pem
  file_permission = "0600"
}

output "ssh_private_key_pem" {
  value = local_sensitive_file.ssh_private_key_pem.content
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.root}/.output/${var.environment}/gpu_node/keys/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

output "shh_private_key_local_path" {
  value = local_sensitive_file.ssh_private_key_pem.filename
}

output "shh_public_key_local_path" {
  value = local_file.ssh_public_key_openssh.filename
}

resource "aws_key_pair" "_key_pair" {
  region          = var.aws_region
  key_name_prefix = "${var.app_prefix}-${var.environment}-key-pair-"
  public_key      = tls_private_key.global_key.public_key_openssh
}

output "aws_key_pair_name" {
  value = aws_key_pair._key_pair.key_name
}
