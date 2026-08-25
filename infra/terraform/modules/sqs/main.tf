resource "aws_sqs_queue" "analytics" {
    name = "${var.name_prefix}-analytics"

    visibility_timeout_seconds = 60

    message_retention_seconds = 345600

    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-analytics"
        Service = "worker"
    })
  
}