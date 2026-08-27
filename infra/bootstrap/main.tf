resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = {
    Name        = var.state_bucket_name
    Project     = "ECSv2"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "cloudflare_zone" "main" {
  name = var.domain_name
}

resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.domain_name}-certificate"
    Project     = "ECSv2"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
  }
}

resource "cloudflare_record" "acm_validation" {
  zone_id = data.cloudflare_zone.main.id

  name = tolist(
    aws_acm_certificate.main.domain_validation_options
  )[0].resource_record_name

  type = "CNAME"

  content = tolist(
    aws_acm_certificate.main.domain_validation_options
  )[0].resource_record_value

  ttl     = 120
  proxied = false
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn

  validation_record_fqdns = [
    cloudflare_record.acm_validation.hostname
  ]

  depends_on = [
    cloudflare_record.acm_validation
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

resource "aws_iam_role" "github_terraform" {
  name = "ECSv2-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:ssyntaxerr@*/ECSv2-Project@*:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "ECSv2-github-actions-role"
    Project     = "ECSv2"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy" "github_terraform_state" {
  name = "ECSv2-terraform-state"
  role = aws_iam_role.github_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_ecr" {
  name = "ECSv2-ecr-deployment"
  role = aws_iam_role.github_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]

        Resource = [
          "arn:aws:ecr:eu-west-2:871916528489:repository/ecs-v2-dev-api-repo",
          "arn:aws:ecr:eu-west-2:871916528489:repository/ecs-v2-dev-worker-repo",
          "arn:aws:ecr:eu-west-2:871916528489:repository/ecs-v2-dev-dashboard-repo"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_ecs" {
  name = "ECSv2-ecs-deployment"
  role = aws_iam_role.github_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = [
          "arn:aws:iam::871916528489:role/ecs-v2-dev-ecs-execution-role",
          "arn:aws:iam::871916528489:role/ecs-v2-dev-api-task-role",
          "arn:aws:iam::871916528489:role/ecs-v2-dev-worker-task-role",
          "arn:aws:iam::871916528489:role/ecs-v2-dev-dashboard-task-role"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_terraform_infrastructure" {
  name = "ECSv2-terraform-infrastructure"
  role = aws_iam_role.github_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EC2Networking"
        Effect = "Allow"

        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:Describe*",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateVpcEndpoint",
          "ec2:DeleteVpcEndpoints",
          "ec2:ModifyVpcEndpoint",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]

        Resource = "*"
      },

      {
        Sid    = "ECS"
        Effect = "Allow"

        Action = [
          "ecs:CreateCluster",
          "ecs:DeleteCluster",
          "ecs:DescribeClusters",
          "ecs:CreateService",
          "ecs:UpdateService",
          "ecs:DeleteService",
          "ecs:DescribeServices",
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTaskDefinitions",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:TagResource",
          "ecs:UntagResource"
        ]

        Resource = "*"
      },

      {
        Sid    = "ElasticLoadBalancing"
        Effect = "Allow"

        Action = [
          "elasticloadbalancing:*"
        ]

        Resource = "*"
      },

      {
        Sid    = "RDS"
        Effect = "Allow"

        Action = [
          "rds:*"
        ]

        Resource = "*"
      },

      {
        Sid    = "ElastiCache"
        Effect = "Allow"

        Action = [
          "elasticache:*"
        ]

        Resource = "*"
      },

      {
        Sid    = "SQS"
        Effect = "Allow"

        Action = [
          "sqs:*"
        ]

        Resource = "*"
      },

      {
        Sid    = "SecretsManager"
        Effect = "Allow"

        Action = [
          "secretsmanager:*"
        ]

        Resource = "*"
      },

      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"

        Action = [
          "logs:*"
        ]

        Resource = "*"
      },

      {
        Sid    = "WAF"
        Effect = "Allow"

        Action = [
          "wafv2:*"
        ]

        Resource = "*"
      },

      {
        Sid    = "IAMManagement"
        Effect = "Allow"

        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:PassRole"
        ]

        Resource = [
          "arn:aws:iam::871916528489:role/ecs-v2-dev-*"
        ]
      },

      {
        Sid    = "ECRManagement"
        Effect = "Allow"

        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DescribeRepositories",
          "ecr:ListTagsForResource",
          "ecr:TagResource",
          "ecr:UntagResource",
          "ecr:GetRepositoryPolicy",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy"
        ]

        Resource = "*"
      }
    ]
  })
}

module "ecr" {
  source = "../terraform/modules/ecr"

  name_prefix = "ecs-v2-dev"

  common_tags = {
    Project     = "ecs-v2"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  repositories = [
    "api-repo",
    "worker-repo",
    "dashboard-repo"
  ]
}