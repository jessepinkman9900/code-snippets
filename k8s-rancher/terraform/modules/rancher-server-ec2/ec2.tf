resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "ssh_private_key_pem" {
  filename        = "${path.root}/.output/${var.environment}/rancher_node/keys/id_rsa"
  content         = tls_private_key.global_key.private_key_pem
  file_permission = "0600"
}

output "ssh_private_key_pem" {
  value = local_sensitive_file.ssh_private_key_pem.content
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.root}/.output/${var.environment}/rancher_node/keys/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

resource "aws_key_pair" "rancher_server_key_pair" {
  region          = var.aws_region
  key_name_prefix = "${var.app_prefix}-${var.environment}-rancher-server-key-pair-"
  public_key      = tls_private_key.global_key.public_key_openssh
}

output "aws_key_pair_name" {
  value = aws_key_pair.rancher_server_key_pair.key_name
}

resource "aws_security_group" "sg_allowall" {
  name   = "${var.app_prefix}-${var.environment}-sg-allowall"
  region = var.aws_region
  vpc_id = var.ec2_config.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "rancher_server" {
  region        = var.aws_region
  ami           = data.aws_ami.sles.id
  instance_type = var.ec2_config.instance_type

  key_name                    = aws_key_pair.rancher_server_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.sg_allowall.id]
  subnet_id                   = var.ec2_config.public_subnet_id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = {
    Name = "${var.app_prefix}-${var.environment}-rancher-server"
  }
}

output "node_username" {
  value = local.node_username
}

output "node_public_ip" {
  value = aws_instance.rancher_server.public_ip
}

output "node_private_ip" {
  value = aws_instance.rancher_server.private_ip
}
