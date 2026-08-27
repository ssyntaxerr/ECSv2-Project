data "aws_ecr_repository" "api" {
  name = "ecs-v2-dev-api-repo"
}

data "aws_ecr_repository" "worker" {
  name = "ecs-v2-dev-worker-repo"
}

data "aws_ecr_repository" "dashboard" {
  name = "ecs-v2-dev-dashboard-repo"
}

data "aws_ssm_parameter" "current_image_tag" {
  name = "/ecs-v2/dev/current-image-tag"
}

data "cloudflare_zone" "main" {
  filter = {
    name = "sufyanokomi.co.uk"
  }
}

data "aws_acm_certificate" "main" {
  domain      = "sufyanokomi.co.uk"
  statuses    = ["ISSUED"]
  most_recent = true
}