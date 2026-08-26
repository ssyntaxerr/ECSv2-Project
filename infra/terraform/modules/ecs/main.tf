resource "aws_ecs_cluster" "ecsv2_cluster" {
  name = "${var.name_prefix}-cluster"

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-cluster"
    Service = "ecs"
  })
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.name_prefix}/api"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Service = "api"
  })
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.name_prefix}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "512"
  memory = "1024"

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.api_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = var.api_image
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
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
          name      = "DATABASE_URL"
          valueFrom = "${var.postgres_secret_arn}:DATABASE_URL::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-api-task"
    Service = "api"
  })
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.name_prefix}/worker"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Service = "worker"
  })
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.name_prefix}-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.worker_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "worker"
      image     = var.worker_image
      essential = true

      portMappings = [
        {
          containerPort = 8090
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = var.sqs_queue_url
        },
        {
          name  = "HEALTH_PORT"
          value = "8090"
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${var.postgres_secret_arn}:DATABASE_URL::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.worker.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-worker-task"
    Service = "worker"
  })
}

resource "aws_cloudwatch_log_group" "dashboard" {
  name              = "/ecs/${var.name_prefix}/dashboard"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Service = "dashboard"
  })
}

resource "aws_ecs_task_definition" "dashboard" {
  family                   = "${var.name_prefix}-dashboard"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.dashboard_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "dashboard"
      image     = var.dashboard_image
      essential = true

      portMappings = [
        {
          containerPort = 8081
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "PORT"
          value = "8081"
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${var.postgres_secret_arn}:DATABASE_URL::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.dashboard.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-dashboard-task"
    Service = "dashboard"
  })
}

resource "aws_ecs_service" "api" {
  name            = "${var.name_prefix}-api-service"
  cluster         = aws_ecs_cluster.ecsv2_cluster.id
  task_definition = aws_ecs_task_definition.api.arn

  desired_count = 2
  launch_type   = "FARGATE"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.api_target_group_arn
    container_name   = "api"
    container_port   = 8080
  }

  health_check_grace_period_seconds = 60

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-api-service"
    Service = "api"
  })
}

resource "aws_ecs_service" "worker" {
  name            = "${var.name_prefix}-worker-service"
  cluster         = aws_ecs_cluster.ecsv2_cluster.id
  task_definition = aws_ecs_task_definition.worker.arn

  desired_count = 1
  launch_type   = "FARGATE"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-worker-service"
    Service = "worker"
  })
}

resource "aws_ecs_service" "dashboard" {
  name            = "${var.name_prefix}-dashboard-service"
  cluster         = aws_ecs_cluster.ecsv2_cluster.id
  task_definition = aws_ecs_task_definition.dashboard.arn

  desired_count = 1
  launch_type   = "FARGATE"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.dashboard_target_group_arn
    container_name   = "dashboard"
    container_port   = 8081
  }

  health_check_grace_period_seconds = 60

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-dashboard-service"
    Service = "dashboard"
  })
}