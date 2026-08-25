resource "aws_vpc" "ecsv2-vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    
    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-vpc"
    })
}

resource "aws_subnet" "priv-subnet" {
    for_each = {
        for index, cidr in var.private_subnet_cidrs :
        index => {
            cidr = cidr
            az = var.availability_zones[index]
        }
    }

    vpc_id = aws_vpc.ecsv2-vpc.id
    cidr_block = each.value.cidr
    availability_zone = each.value.az

    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-private-${each.value.az}"
        Tier = "private"
    })
}

resource "aws_route_table" "priv-rt" {
    vpc_id = aws_vpc.ecsv2-vpc.id

    tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-rt"
    Tier = "private"
  })
}

resource "aws_route_table_association" "priv-rt-assoc" {
    for_each = aws_subnet.priv-subnet
    subnet_id = each.value.id
    route_table_id = aws_route_table.priv-rt.id
}

resource "aws_vpc_endpoint" "s3_endpoint" {
    vpc_id = aws_vpc.ecsv2-vpc
    service_name = "com.amazonaws.${var.aws_region}.s3"
    
    vpc_endpoint_type = "Gateway"

    route_table_ids = [
        aws_route_table.priv-rt.id
    ]

    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-s3-endpoint"
    })
}

locals {
    interface_endpoint_services = [
        "ecr.api",
        "ecr.dkr",
        "logs",
        "sqs",
    ]
}

resource "aws_vpc_endpoint" "interface" {
    for_each = toset(local.interface_endpoint_services)

    vpc_id = aws_vpc.ecsv2-vpc
    service_name = "com.amazonaws.${var.aws_region}.${each.value}"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true

    subnet_ids = [
        for subnet in aws_subnet.priv-subnet : subnet.id
    ]

    security_group_ids = [
        aws_security_group.vpc_endpoints.id
    ]

    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-${each.value}-endpoint"
    })
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name_prefix}-vpc-endpoints"
  description = "Allow HTTPS traffic to VPC endpoints"
  vpc_id      = aws_vpc.ecsv2-vpc

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-vpc-endpoints-sg"
  })
}

resource "aws_subnet" "pub-subnet" {
  for_each = {
    for index, cidr in var.public_subnet_cidrs :
    index => {
      cidr = cidr
      az   = var.availability_zones[index]
    }
  }

  vpc_id = aws_vpc.ecsv2-vpc.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-${each.value.az}"
    Tier = "public"
  })
}