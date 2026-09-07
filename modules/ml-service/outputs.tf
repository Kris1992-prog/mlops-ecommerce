output "bucket_name" {
  description = "Nome del bucket S3 per i modelli ML"
  value       = aws_s3_bucket.ml_models.bucket
}

output "aws_access_key_id" {
  description = "Access Key ID IAM per accesso S3 ed ECR da K8s"
  value       = aws_iam_access_key.k8s_ml_user_key.id
  sensitive   = true
}

output "aws_secret_access_key" {
  description = "Secret Access Key IAM per accesso S3 ed ECR da K8s"
  value       = aws_iam_access_key.k8s_ml_user_key.secret
  sensitive   = true
}

output "ecr_ml_api_url" {
  description = "URL repository ECR per ml-recommendations-api"
  value       = aws_ecr_repository.ml_api.repository_url
}

output "ecr_ml_trainer_url" {
  description = "URL repository ECR per ml-recommendations-trainer"
  value       = aws_ecr_repository.ml_trainer.repository_url
}

output "ecr_llm_gateway_url" {
  description = "URL repository ECR per llm-gateway"
  value       = aws_ecr_repository.llm_gateway.repository_url
}

output "ecr_registry_id" {
  description = "AWS account ID del registry ECR"
  value       = aws_ecr_repository.ml_api.registry_id
}
