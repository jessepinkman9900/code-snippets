data "aws_vpc" "requester" {
  region = var.vpc_peering_config.requester_region
  id     = var.vpc_peering_config.requester_vpc_id
}

data "aws_vpc" "accepter" {
  region = var.vpc_peering_config.accepter_region
  id     = var.vpc_peering_config.accepter_vpc_id
}

# create vpc peering connection
resource "aws_vpc_peering_connection" "peer" {
  region      = var.vpc_peering_config.requester_region
  vpc_id      = data.aws_vpc.requester.id
  peer_vpc_id = var.vpc_peering_config.accepter_vpc_id
  peer_region = var.vpc_peering_config.accepter_region
  # auto accept only for same region peering
  auto_accept = var.vpc_peering_config.auto_accept && var.vpc_peering_config.accepter_region == var.vpc_peering_config.requester_region

  tags = merge(
    var.common_tags,
    {
      Name            = "${var.common_tags.app_prefix}-${var.common_tags.environment}-vpc-peering-${var.vpc_peering_config.requester_region}-${var.vpc_peering_config.accepter_region}"
      Type            = "vpc-peering"
      RequesterRegion = var.vpc_peering_config.requester_region
      AccepterRegion  = var.vpc_peering_config.accepter_region
    }
  )
}

# accept peering connection in accepter region
resource "aws_vpc_peering_connection_accepter" "peer" {
  region                    = var.vpc_peering_config.accepter_region
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.common_tags.app_prefix}-${var.common_tags.environment}-vpc-peering-accepter-${var.vpc_peering_config.requester_region}-${var.vpc_peering_config.accepter_region}"
      Type = "vpc-peering-accepter"
    }
  )
}

output "peer_connection_id" {
  value = aws_vpc_peering_connection.peer.id
}

output "peer_connection_status" {
  value = aws_vpc_peering_connection.peer.accept_status
}

output "requester_vpc" {
  value = {
    region     = var.vpc_peering_config.requester_region
    vpc_id     = data.aws_vpc.requester.id
    cidr_block = data.aws_vpc.requester.cidr_block
  }
}

# route for requester vpc (private route tables)
resource "aws_route" "requester_private" {
  depends_on = [aws_vpc_peering_connection_accepter.peer]
  region     = var.vpc_peering_config.requester_region
  for_each   = var.vpc_peering_config.requester_private_route_table_ids

  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  route_table_id            = each.value
  destination_cidr_block    = var.vpc_peering_config.accepter_cidr_block
}

# route for requester vpc (public route tables)
resource "aws_route" "requester_public" {
  depends_on = [aws_vpc_peering_connection_accepter.peer]
  region     = var.vpc_peering_config.requester_region

  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  route_table_id            = var.vpc_peering_config.requester_public_route_table_id
  destination_cidr_block    = var.vpc_peering_config.accepter_cidr_block
}

# route for accepter vpc (private route tables)
resource "aws_route" "accepter_private" {
  depends_on = [aws_vpc_peering_connection_accepter.peer]
  region     = var.vpc_peering_config.accepter_region
  for_each   = var.vpc_peering_config.accepter_private_route_table_ids

  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  route_table_id            = each.value
  destination_cidr_block    = var.vpc_peering_config.requester_cidr_block
}

# route for accepter vpc (public route tables)
resource "aws_route" "accepter_public" {
  depends_on = [aws_vpc_peering_connection_accepter.peer]
  region     = var.vpc_peering_config.accepter_region

  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  route_table_id            = var.vpc_peering_config.accepter_public_route_table_id
  destination_cidr_block    = var.vpc_peering_config.requester_cidr_block
}

# # enable DNS resolution for peering connection (requester side only) - conditional
# resource "aws_vpc_peering_connection_options" "requester" {
#   count = data.aws_vpc.requester.enable_dns_hostnames && data.aws_vpc.accepter.enable_dns_hostnames ? 1 : 0
#   depends_on = [ aws_vpc_peering_connection_accepter.peer ]
#   region = var.vpc_peering_config.requester_region
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
#   requester {
#     allow_remote_vpc_dns_resolution = true
#   }
# }

# # enable DNS resolution for peering connection (accepter side only) - conditional
# resource "aws_vpc_peering_connection_options" "accepter" {
#   count = data.aws_vpc.requester.enable_dns_hostnames && data.aws_vpc.accepter.enable_dns_hostnames ? 1 : 0
#   depends_on = [ aws_vpc_peering_connection_accepter.peer ]
#   region = var.vpc_peering_config.accepter_region
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
#   accepter {
#     allow_remote_vpc_dns_resolution = true
#   }
# }
