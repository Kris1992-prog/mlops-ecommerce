variable "environment" {
  type        = string
  description = "Ambiente di deployment"
  default     = "dev"
}

variable "secret_name" {
  type        = string
  description = "Nome del segreto su AWS Secrets Manager"
  default     = "app-db-credentials-v1"
}

variable "db_username" {
  type        = string
  description = "Username da salvare nel Secret"
  default     = "admin_user"
}