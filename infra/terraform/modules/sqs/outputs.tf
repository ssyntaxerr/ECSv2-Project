output "queue_arn" {
  value = aws_sqs_queue.analytics.arn
}

output "queue_url" {
  value = aws_sqs_queue.analytics.url
}

output "queue_name" {
  value = aws_sqs_queue.analytics.name
}

output "dlq_arn" {
  value = aws_sqs_queue.analytics_dlq.arn
}