
resource "aws_vpc" "emr_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.app_prefix}-${var.environment}-emr-vpc"
  }
}

resource "aws_subnet" "emr_vpc_public_subnet1" {
  vpc_id     = aws_vpc.emr_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "${var.app_prefix}-${var.environment}-emr-vpc-public-subnet1"
  }
}

resource "aws_subnet" "emr_vpc_private_subnet1" {
  vpc_id     = aws_vpc.emr_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "${var.app_prefix}-${var.environment}-emr-vpc-private-subnet1"
  }
}

resource "aws_internet_gateway" "emr_vpc_igw" {
  vpc_id = aws_vpc.emr_vpc.id

  tags = {
    Name = "${var.app_prefix}-${var.environment}-emr-vpc-igw"
  }
}

resource "aws_route_table" "emr_route_table" {
  vpc_id = aws_vpc.emr_vpc.id

  tags = {
    Name = "${var.app_prefix}-${var.environment}-emr-vpc-route-table"
  }
}

resource "aws_route" "emr_route_table_igw_route" {
  route_table_id         = aws_route_table.emr_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.emr_vpc_igw.id
}

resource "aws_route_table_association" "emr_route_table_association1" {
  subnet_id      = aws_subnet.emr_vpc_public_subnet1.id
  route_table_id = aws_route_table.emr_route_table.id
}

resource "aws_eip" "emr_ip" {
  domain = "vpc"

  tags = {
    Name = "${var.app_prefix}-${var.environment}-emr-elastic-ip"
  }
}

resource "aws_nat_gateway" "emr_vpc_nat_gateway" {
  allocation_id = aws_eip.emr_ip.id
  subnet_id     = aws_subnet.emr_vpc_public_subnet1.id

  tags = {
    Name = "${var.app_prefix}-${var.environment}-emr-vpc-nat-gateway"
  }
}

resource "aws_route_table" "emr_ngw_route_table" {
  vpc_id = aws_vpc.emr_vpc.id

  tags = {
    Name = "${var.app_prefix}-${var.environment}-emr-vpc-ngw-route-table"
  }
}

resource "aws_route" "emr_ngw_route_table_ngw_route" {
  route_table_id         = aws_route_table.emr_ngw_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.emr_vpc_nat_gateway.id
}

resource "aws_route_table_association" "emr_ngw_route_table_association1" {
  subnet_id      = aws_subnet.emr_vpc_private_subnet1.id
  route_table_id = aws_route_table.emr_ngw_route_table.id
}

resource "aws_route_table" "emr_vpce_route_table" {
  vpc_id = aws_vpc.emr_vpc.id

  tags = {
    Name = "${var.app_prefix}-${var.environment}-emr-vpc-vpce-route-table"
  }
}

resource "aws_security_group" "emr_security_group" {
  name   = "${var.app_prefix}-${var.environment}-emr-security-group"
  vpc_id = aws_vpc.emr_vpc.id
}

resource "aws_security_group_rule" "emr_security_group_rule" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.emr_security_group.id
}
