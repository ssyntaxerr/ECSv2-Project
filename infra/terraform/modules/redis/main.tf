resource "aws_elasticache_subnet_group" "redis_subnet_group" {
    name = "${var.name_prefix}-redis-subnet-group"
    subnet_ids = var.private_subnet_ids

    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-redis-subnet-group"
        Service = "cache"
    })
}