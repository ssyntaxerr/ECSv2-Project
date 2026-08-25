resource "aws_db_subnet_group" "postgres_subnet_group" {
    name = "${var.name_prefix}-postgres-subnet-group"
    subnet_ids = var.private_subnet_ids

    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-postgres-subnet-group"
    })
}

resource "aws_security_group" "postgres_sg" {
  name        = "${var.name_prefix}-postgres-sg"
  description = "Security group for PostgreSQL RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL access from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-postgres-sg"
  })
}