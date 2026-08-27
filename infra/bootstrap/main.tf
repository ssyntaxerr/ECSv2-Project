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
            "token.actions.githubusercontent.com:sub" = "repo:ssyntaxerr/ECSv2-Project:*"
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