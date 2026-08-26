output "alb_arn" {
  value = aws_lb.alb.arn
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "api_target_group_arn" {
  value = aws_lb_target_group.api.arn
}

output "dashboard_target_group_arn" {
  value = aws_lb_target_group.dashboard.arn
}