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