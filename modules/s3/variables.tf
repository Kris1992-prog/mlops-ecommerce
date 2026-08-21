variable "environment" {
  type        = string
  description = "Ambiente di deployment"
  default     = "dev"
}

variable "s3_bucket_name" {
  type        = string
  description = "Nome del bucket S3 principale"
  default     = "kris-bucket-test-2026-nuovo"
}

variable "s3_log_bucket_name" {
  type        = string
  description = "Nome del bucket S3 dedicato ai log di accesso"
  default     = "kris-bucket-logs-2026"
}