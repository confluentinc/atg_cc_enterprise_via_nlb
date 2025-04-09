terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

locals {
  //availability_zones = ["${var.region}a", "${var.region}b"]
  availability_zones = ["${var.region}a"]
}


resource "aws_security_group" "cc_access" {
  description = "Confluent Cloud security group for exposing an Enterprise Cluster via a public IP address"
  vpc_id = aws_vpc.vpc.id
  name = "${var.env_prefix}-cc_access"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    // This should be locked down as much as possible
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    // This should be locked down as much as possible
    cidr_blocks = ["0.0.0.0/0"]
  }
  // Egress rules allow the NLB to forward traffic to internal resources
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    // This should be locked down as much as possible
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    // This should be locked down as much as possible
    cidr_blocks = ["10.0.0.0/16"]
  }
  tags = {
    Owner       = var.owner
  }
}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.env_prefix}-vpc"
    Environment = var.environment
    Owner       = var.owner
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.env_prefix}-${element(local.availability_zones, count.index)}-public-subnet"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
}


# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.env_prefix}-${element(local.availability_zones, count.index)}-private-subnet"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
}

#Internet gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name"        = "${var.env_prefix}-igw"
    "Environment" = var.environment
    Owner       = var.owner
  }
}

/*
# Elastic-IP (eip) for NAT
resource "aws_eip" "nat_eip" {
  domain        = "vpc"
  tags = {
    Name        = "${var.env_prefix}-nat-ip"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
  depends_on = [aws_internet_gateway.ig]
}*/

# Routing tables to route traffic for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
}

# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
}

# Route for Internet Gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# Route table associations for both Public & Private Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}
# Elastic-IP (eip) for NLB
resource "aws_eip" "nlb_eip" {
  domain        = "vpc"
  tags = {
    Name        = "${var.env_prefix}-nlb-ip"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
}

/*
NLB is needed to expose an IP address to the internet and route to the PL endpoints
*/
resource "aws_lb" "public_nlb" {
  name               = "${var.env_prefix}-public-nlb"
  load_balancer_type = "network"
  internal           = false
  //subnets            = [for subnet in aws_subnet.public : subnet.id]
  security_groups    = [aws_security_group.cc_access.id]

  subnet_mapping {
    subnet_id     = aws_subnet.public_subnet[0].id
    allocation_id = aws_eip.nlb_eip.id
  }

  tags = {
    //Name        = "${var.env_prefix}-public-nlb"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
  enable_cross_zone_load_balancing = true
}
resource "aws_lb_target_group" "cc-kafka-tg" {
  port     = 9092
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id
  target_type = "ip"
  name_prefix = "kafka-"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name     = "${var.env_prefix}-kafka-tg"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
}
resource "aws_lb_target_group" "cc-rest-tg" {
  port     = 443
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id
  target_type = "ip"
  name_prefix = "rest-"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name     = "${var.env_prefix}-rest-tg"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
}

resource "aws_lb_target_group_attachment" "cc-kakfa-to-pl"{
  target_group_arn = aws_lb_target_group.cc-kafka-tg.arn
  // user join() to deal with the "is set of string with 1 element" issue
  //target_id = join("", var.pl_endpoints[0].network_interface_ids)
  target_id = tolist(var.pl_endpoints[0].subnet_configuration)[0].ipv4
  port = 9092
}
resource "aws_lb_target_group_attachment" "cc-rest-to-pl"{
  target_group_arn = aws_lb_target_group.cc-rest-tg.arn
  // user join() to deal with the "is set of string with 1 element" issue
  //target_id = join("", var.pl_endpoints[0].network_interface_ids)
  target_id = tolist(var.pl_endpoints[0].subnet_configuration)[0].ipv4
  port = 443
}
resource "aws_lb_listener" "cc-kafka-listener" {
  load_balancer_arn = aws_lb.public_nlb.id
  port              = "9092"
  protocol          = "TCP"
  depends_on        = [aws_lb_target_group.cc-kafka-tg]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cc-kafka-tg.arn
  }
  tags = {
    Name        = "${var.environment}-public-nlb-kafka"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
}
resource "aws_lb_listener" "cc-rest-listener" {
  load_balancer_arn = aws_lb.public_nlb.id
  port              = "443"
  protocol          = "TCP"
  depends_on        = [aws_lb_target_group.cc-rest-tg]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cc-rest-tg.arn
  }
  tags = {
    Name        = "${var.environment}-public-nlb-rest"
    Environment = "${var.environment}"
    Owner       = var.owner
  }
}

