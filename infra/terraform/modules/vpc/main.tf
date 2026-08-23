resource "aws_vpc" "ecsv2-vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    
    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-vpc"
    })
}