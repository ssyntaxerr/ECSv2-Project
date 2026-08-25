resource "aws_ecs_cluster" "ecsv2_cluster" {
  name = "${var.name_prefix}-cluster"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-cluster"
    Service = "ecs"
  })
}