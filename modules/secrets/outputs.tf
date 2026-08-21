output "db_password" {
  description = "Password generata casualmente per il database"
  value       = random_password.db_password.result
  sensitive   = true
}

output "secret_arn" {
  description = "ARN del Secret memorizzato su AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_id" {
  description = "ID del Secret"
  value       = aws_secretsmanager_secret.db_credentials.id
}