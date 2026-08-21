variable "environment" {
  type        = string
  description = "Ambiente di deployment"
  default     = "dev"
}

variable "app_replicas" {
  type        = number
  description = "Numero di repliche del deployment Kubernetes"
  default     = 2
}

variable "app_image" {
  type        = string
  description = "Nome completo dell'immagine Docker"
  default     = "kris1992/progetto-ecommerce"
}

variable "app_image_tag" {
  type        = string
  description = "Tag dell'immagine Docker"
  default     = "latest"
}

variable "db_host" {
  type        = string
  description = "Host/Address del database"
}

variable "db_name" {
  type        = string
  description = "Nome del database"
}

variable "db_username" {
  type        = string
  description = "Username del database"
}

variable "db_password" {
  type        = string
  description = "Password del database"
  sensitive   = true
}

variable "helm_chart_path" {
  type        = string
  description = "Percorso relativo o assoluto al file tgz del chart Helm ingress-nginx"
  default     = "./ingress-nginx-4.15.1.tgz"
}

variable "ml_aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "ml_aws_secret_access_key" {
  type      = string
  sensitive = true
}