output "bucket_id" {
  description = "ID del bucket principale"
  value       = aws_s3_bucket.mio_bucket.id
}

output "bucket_arn" {
  description = "ARN del bucket principale"
  value       = aws_s3_bucket.mio_bucket.arn
}

output "log_bucket_id" {
  description = "ID del bucket dedicato ai log"
  value       = aws_s3_bucket.log_bucket.id
}