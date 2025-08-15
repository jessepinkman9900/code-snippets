resource "aws_security_group" "sg_allowall" {
  region      = var.aws_region
  name_prefix = "${var.app_prefix}-${var.environment}-sg-allowall-"
  description = "Security group for GPU node - allows all traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_prefix}-${var.environment}-sg-allowall"
  }
}
