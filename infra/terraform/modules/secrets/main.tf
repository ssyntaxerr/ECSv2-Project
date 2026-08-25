resource "aws_secretsmanager_secret" "postgres_secret" {
    name = "${var.name_prefix}/postgres-secret"

    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}/postgres-secret"
        Service = "database"
    })
}

resource "aws_secretsmanager_secret_version" "postgres_secrets" {
    secret_id = aws_secretsmanager_secret.postgres_secret.id
    
    secret_string = jsonencode({
        username = var.db_username
        password = var.db_password
    })
}