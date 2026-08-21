output "db_endpoint" {
  description = "Endpoint di connessione del database RDS MySQL (host:port)"
  value       = aws_db_instance.ecommerce_db.endpoint
}

output "db_address" {
  description = "Indirizzo host del database RDS MySQL"
  value       = aws_db_instance.ecommerce_db.address
}

output "db_port" {
  description = "Porta su cui risponde il database RDS MySQL"
  value       = aws_db_instance.ecommerce_db.port
}

output "db_name" {
  description = "Nome del database creato"
  value       = aws_db_instance.ecommerce_db.db_name
}