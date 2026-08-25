resource "aws_sqs_queue" "analytics" {
    name = "${var.name_prefix}-analytics"

    visibility_timeout_seconds = 60

    message_retention_seconds = 345600

    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-analytics"
        Service = "worker"
    })
}

resource "aws_sqs_queue" "analytics_dlq" {
    name = "${var.name_prefix}-analytics-dlq"

    message_retention_seconds = 1209600

    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-analytics-dlq"
        Service = "worker"
    })
}

resource "aws_sqs_queue_redrive_policy" "analytics_redrive" {
    queue_url = aws_sqs_queue.analytics.id
    
    redrive_policy = jsonencode({
        deadLetterTargetArn = aws_sqs.analytics_dlq.arn
        maxReceiveCount = 3
    })
}