variable "bucket_name" {
  type        = string
  description = "Nome del bucket S3 per i modelli ML"
  default     = "ecommerce-ml-models-prod"
}

variable "region" {
  type        = string
  description = "Regione AWS in cui deployare le risorse ML"
  default     = "eu-south-1"
}

variable "environment" {
  type        = string
  description = "Ambiente di deployment"
  default     = "dev"
}
