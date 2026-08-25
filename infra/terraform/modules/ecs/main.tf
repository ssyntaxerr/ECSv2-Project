resource "aws_ecs_cluster" "ecsv2_cluster" {
  name = "${var.name_prefix}-cluster"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-cluster"
    Service = "ecs"
  })
}

resource "aws_security_group" "ecs_sg" {
  name        = "${var.name_prefix}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-ecs-sg"
    Service = "ecs"
  })
}