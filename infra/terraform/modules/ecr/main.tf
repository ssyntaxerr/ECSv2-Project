resource "aws_ecr_repository" "ecsv2-repos" {
    for_each = toset(var.repositories)

    name = "${var.name_prefix}-${each.value}"
    image_tag_mutability = "IMMUTABLE"

    image_scanning_configuration {
      scan_on_push = true
    }
    
    tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-${each.value}"
    Service = each.value
  })
}