resource "aws_iam_role" "ecs_execution" {
  name = "${var.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ecs-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role = aws_iam_role.ecs_execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${var.name_prefix}-ecs-execution-secrets-policy"
  role = aws_iam_role.ecs_execution.name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = var.postgres_secret_arn
      }
    ]
  })
}

resource "aws_iam_role" "api_task" {
  name = "${var.name_prefix}-api-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-api-task-role"
    Service = "api"
  })
}

resource "aws_iam_role" "worker_task" {
  name = "${var.name_prefix}-worker-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-worker-task-role"
    Service = "worker"
  })
}

resource "aws_iam_role" "dashboard_task" {
  name = "${var.name_prefix}-dashboard-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-dashboard-task-role"
    Service = "dashboard"
  })
}

resource "aws_iam_role_policy" "api_sqs" {
  name = "${var.name_prefix}-api-sqs-policy"
  role = aws_iam_role.api_task.name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:SendMessage"
        ]

        Resource = var.queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "worker_sqs" {
  name = "${var.name_prefix}-worker-sqs-policy"
  role = aws_iam_role.worker_task.name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]

        Resource = var.queue_arn
      }
    ]
  })
}