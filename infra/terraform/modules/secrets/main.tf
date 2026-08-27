resource "aws_secretsmanager_secret" "postgres_secret" {
  name = "${var.name_prefix}/postgres-secret"
  recovery_window_in_days = 0

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}/postgres-secret"
    Service = "database"
  })
}

resource "aws_secretsmanager_secret_version" "postgres_secrets" {
  secret_id = aws_secretsmanager_secret.postgres_secret.id

  secret_string = jsonencode({
    DATABASE_URL = "postgresql://${var.db_username}:${var.db_password}@${var.db_endpoint}:${var.db_port}/${var.db_name}?sslmode=require"
  })
}