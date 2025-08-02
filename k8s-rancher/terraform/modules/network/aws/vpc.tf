resource "aws_vpc" "vpc" {
  region = var.aws_region
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.app_prefix}-${var.environment}-vpc"
  }
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "availability_zones" {
  value = data.aws_availability_zones.available.names
}

# internet gateway - bidirectional communication between VPC and internet
# HA default across all AZs
resource "aws_internet_gateway" "igw" {
  region = var.aws_region
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.app_prefix}-${var.environment}-igw"
  }
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

# public subnets
resource "aws_subnet" "public" {
  region = var.aws_region
  count = local.az_count

  vpc_id     = aws_vpc.vpc.id
  cidr_block = local.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_prefix}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "public"
  }
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  value = aws_subnet.public[*].cidr_block
}

# private subnets
resource "aws_subnet" "private" {
  region = var.aws_region
  count = local.az_count

  vpc_id     = aws_vpc.vpc.id
  cidr_block = local.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_prefix}-${var.environment}-private-subnet-${count.index + 1}"
    Type = "private"
  }
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  value = aws_subnet.private[*].cidr_block
}


# elastic ip for NAT gateways
resource "aws_eip" "eip" {
  region = var.aws_region
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0

  domain = "vpc"
  depends_on = [ aws_internet_gateway.igw ]
  tags = {
    Name = "${var.app_prefix}-${var.environment}-eip-${count.index + 1}"
  }
}

# create NAT gateways - outbound only internet access to private subnets
resource "aws_nat_gateway" "nat_gateway" {
  region = var.aws_region
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0

  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on = [ aws_internet_gateway.igw ]

  tags = {
    Name = "${var.app_prefix}-${var.environment}-nat-gateway-${count.index + 1}"
  }
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.nat_gateway[*].id
}

# create route table for public subnets
resource "aws_route_table" "public" {
  region = var.aws_region
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.app_prefix}-${var.environment}-public-route-table"
  }
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

# create route tables for private subnets
resource "aws_route_table" "private" {
  region = var.aws_region
  count = var.enable_nat_gateway ? local.az_count : 1

  vpc_id = aws_vpc.vpc.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.nat_gateway[0].id : aws_nat_gateway.nat_gateway[count.index].id
    }
  }

  tags = {
    Name = "${var.app_prefix}-${var.environment}-private-route-table-${count.index + 1}"
  }
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

# associate public subnets with public route table
resource "aws_route_table_association" "public" {
  region = var.aws_region
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# associate private subnets with private route table
resource "aws_route_table_association" "private" {
  region = var.aws_region
  count = local.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id : aws_route_table.private[0].id
}
