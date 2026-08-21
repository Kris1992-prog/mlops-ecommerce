# 1. Genera una password casuale e sicura
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. Crea il contenitore del segreto su AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.secret_name}-${var.environment}"
  recovery_window_in_days = 0 # Consente la cancellazione immediata in caso di terraform destroy

  tags = {
    Name        = "${var.secret_name}-${var.environment}"
    Environment = var.environment
  }
}

# 3. Salva la coppia Username/Password all'interno del Secret
resource "aws_secretsmanager_secret_version" "db_credentials_val" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}