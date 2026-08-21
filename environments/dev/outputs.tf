output "ec2_public_ip" {
  description = "Indirizzo IP pubblico del server EC2 / K3s"
  value       = module.ec2.public_ip
}

output "rds_endpoint" {
  description = "Endpoint del Database RDS MySQL"
  value       = module.rds.db_endpoint
}

output "s3_bucket_name" {
  description = "Nome del bucket S3 principale"
  value       = module.s3.bucket_id
}

output "s3_log_bucket_name" {
  description = "Nome del bucket S3 per i log"
  value       = module.s3.log_bucket_id
}

output "secrets_arn" {
  description = "ARN del Secret su AWS Secrets Manager"
  value       = module.secrets.secret_arn
}