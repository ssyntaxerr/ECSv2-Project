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
    vpc_id = aws_vpc.ecsv2-vpc

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