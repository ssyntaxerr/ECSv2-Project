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
    
    policy_arn = "arn:aws:iam:aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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

resource "aws_iam_role" "ecs_task" {
    name = "${var.name_prefix}-ecs-task-role"

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
        Name = "${var.name_prefix}-ecs-task-role"
    })
}

resource "aws_iam_role_policy" "ecs_task_sqs" {
  name = "${var.name_prefix}-ecs-task-sqs-policy"
  role = aws_iam_role.ecs_task.name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessages"
        ]

        Resource = var.queue_arn
      }
    ]
  })
}