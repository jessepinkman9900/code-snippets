data "aws_ami" "ubuntu_cuda" {
  region      = var.aws_region
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04) ????????"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_availability_zones" "available" {
  region = var.aws_region
  state = "available"
  
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_ec2_instance_type_offerings" "gpu_zones" {
  filter {
    name   = "instance-type"
    values = [var.ec2_config.instance_type]
  }
  
  filter {
    name   = "location"
    values = data.aws_availability_zones.available.names
  }
  
  location_type = "availability-zone"
}

data "aws_vpc" "default" {
  region  = var.aws_region
  default = true
}

data "aws_subnets" "default" {
  region  = var.aws_region
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  
  filter {
    name   = "availability-zone"
    values = data.aws_ec2_instance_type_offerings.gpu_zones.locations
  }
}
