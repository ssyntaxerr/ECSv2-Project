data "aws_ecr_repository" "api" {
  name = "ecs-v2-dev-api-repo"
}

data "aws_ecr_repository" "worker" {
  name = "ecs-v2-dev-worker-repo"
}

data "aws_ecr_repository" "dashboard" {
  name = "ecs-v2-dev-dashboard-repo"
}