output "vpc_id" {
    value = aws_vpc.ecsv2-vpc.id
}

output "private_subnet_ids" {
    value = [for subnet in aws_subnet.priv-subnet : subnet.id]
}