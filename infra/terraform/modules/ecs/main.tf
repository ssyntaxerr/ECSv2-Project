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

resource "aws_cloudwatch_log_group" "api" {
  name = "/ecs/${var.name_prefix}/api"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Service = "api"
  })
}

resource "aws_ecs_task_definition" "api" {
  family = "${var.name_prefix}-api"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "512"
  memory = "1024"

  execution_role_arn = var.execution_role_arn
  task_role_arn = var.task_role_arn

  container_definitions = jsonencode([
    {
      name = "api"
      image = var.api_image
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol = "tcp"
        }
      ]

      environment = [
        {
          name  = "REDIS_URL"
          value = "rediss://${var.redis_endpoint}:${var.redis_port}"
        },
        {
          name  = "SQS_QUEUE_URL"
          value = var.sqs_queue_url
        },
        {
          name  = "PORT"
          value = "8080"
        }
      ]

      secrets = [
        {
          name = "DATABASE_URL"
          valueFrom = "${var.postgres_secret_arn}:DATABASE_URL::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group = aws_cloudwatch_log_group.api.name
          awslogs-region = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-api-task"
    Service = "api"
  })
}

resource "aws_cloudwatch_log_group" "worker" {
  name = "/ecs/${var.name_prefix}/worker"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Service = "worker"
  })
}

resource "aws_ecs_task_definition" "worker" {
  family = "${var.name_prefix}-worker"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu = "256"
  memory = "512"

  execution_role_arn = var.execution_role_arn
  task_role_arn = var.task_role_arn

  container_definitions = jsonencode([
    {
      name = "worker"
      image = var.worker_image
      essential = true

      portMappings = [
        {
          containerPort = 8090
          protocol = "tcp"
        }
      ]

      environment = [
        {
          name = "SQS_QUEUE_URL"
          value = var.sqs_queue_url
        },
        {
          name = "HEALTH_PORT"
          value = "8090"
        }
      ]

      secrets = [
        {
          name = "DATABASE_URL"
          valueFrom = "${var.postgres_secret_arn}:DATABASE_URL::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group = aws_cloudwatch_log_group.worker.name
          awslogs-region = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-worker-task"
    Service = "worker"
  })
}

resource "aws_cloudwatch_log_group" "dashboard" {
  name = "/ecs/${var.name_prefix}/dashboard"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Service = "dashboard"
  })
}