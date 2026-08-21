output "bucket_name" {
  value = aws_s3_bucket.ml_models.bucket
}

output "aws_access_key_id" {
  value     = aws_iam_access_key.k8s_ml_user_key.id
  sensitive = true
}

output "aws_secret_access_key" {
  value     = aws_iam_access_key.k8s_ml_user_key.secret
  sensitive = true
}

output "ecr_ml_api_url" {
  value = aws_ecr_repository.ml_api.repository_url
}

output "ecr_ml_trainer_url" {
  value = aws_ecr_repository.ml_trainer.repository_url
}
