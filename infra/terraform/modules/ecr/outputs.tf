output "repo_urls" {
  value = {
    for name, repository in aws_ecr_repository.ecsv2-repos :
    name => repository.repository_url
  }
}

output "repo_arns" {
  value = {
    for name, repository in aws_ecr_repository.ecsv2-repos :
    name => repository.arn
  }
}