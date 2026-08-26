output "db_endpoint" {
  value = aws_db_instance.postgres.address
}

output "db_port" {
  value = aws_db_instance.postgres.port
}

output "db_name" {
  value = aws_db_instance.postgres.db_name
}

output "db_username" {
  value     = aws_db_instance.postgres.username
  sensitive = true
}

output "db_sg_id" {
  value = aws_security_group.postgres_sg.id
}