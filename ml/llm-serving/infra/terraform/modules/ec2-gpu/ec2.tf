resource "aws_instance" "gpu_node" {
  region            = var.aws_region
  ami               = data.aws_ami.ubuntu_cuda.id
  instance_type     = var.ec2_config.instance_type
  availability_zone = length(data.aws_ec2_instance_type_offerings.gpu_zones.locations) > 0 ? data.aws_ec2_instance_type_offerings.gpu_zones.locations[0] : data.aws_availability_zones.available.names[0]

  key_name                    = aws_key_pair._key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.sg_allowall.id]
  subnet_id                   = length(data.aws_subnets.default.ids) > 0 ? data.aws_subnets.default.ids[0] : null
  associate_public_ip_address = true

  force_destroy = true

  # Spot instance configuration
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "stop"
      spot_instance_type             = "persistent"
      max_price                      = "1.00"  # Increased for g6.xlarge availability
    }
  }

  root_block_device {
    volume_size = 512 
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
    Name = "${var.app_prefix}-${var.environment}-gpu-node"
  }
}

output "node_username" {
  value = local.node_username
}

output "node_public_ip" {
  value = aws_instance.gpu_node.public_ip
}

output "node_private_ip" {
  value = aws_instance.gpu_node.private_ip
}
