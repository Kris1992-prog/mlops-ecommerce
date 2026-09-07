output "s3_bucket_name" {
  value       = module.ml_infra.bucket_name
  description = "Nome del bucket S3 per i modelli ML"
}

output "ecr_ml_api_url" {
  value       = module.ml_infra.ecr_ml_api_url
  description = "URL ECR per il servizio API ML"
}

output "ecr_ml_trainer_url" {
  value       = module.ml_infra.ecr_ml_trainer_url
  description = "URL ECR per il trainer ML"
}

output "ecr_llm_gateway_url" {
  value       = module.ml_infra.ecr_llm_gateway_url
  description = "URL ECR per il gateway LLM"
}