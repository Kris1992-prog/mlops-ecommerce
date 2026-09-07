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
  description = "Nome dell'immagine Docker per l'app e-commerce"
  default     = "ecommerce-app"
}

variable "app_image_tag" {
  type        = string
  description = "Tag dell'immagine Docker"
  default     = "latest"
}

variable "helm_chart_path" {
  type        = string
  description = "Percorso relativo o assoluto al file tgz del chart Helm ingress-nginx"
  default     = "./ingress-nginx-4.15.1.tgz"
}

variable "mysql_root_password" {
  type        = string
  description = "Password root per il server MySQL locale"
  sensitive   = true
}

variable "mysql_database" {
  type        = string
  description = "Nome del database MySQL da creare"
  default     = "ecommercedb"
}

variable "mysql_user" {
  type        = string
  description = "Username applicativo MySQL"
  default     = "kris_admin"
}

variable "mysql_password" {
  type        = string
  description = "Password applicativa MySQL"
  sensitive   = true
}

variable "ml_api_image" {
  type        = string
  description = "URL immagine ECR per il servizio API di raccomandazione ML"
}

variable "ml_trainer_image" {
  type        = string
  description = "URL immagine ECR per il job di retraining del modello ML"
}

variable "llm_gateway_image" {
  type        = string
  description = "URL immagine ECR per il gateway LLM"
}

variable "ecr_registry_id" {
  type        = string
  description = "AWS account ID del registry ECR (per il token di autenticazione)"
}

variable "ml_aws_access_key_id" {
  type        = string
  description = "Access Key ID IAM per accesso S3 ed ECR da K8s"
  sensitive   = true
}

variable "ml_aws_secret_access_key" {
  type        = string
  description = "Secret Access Key IAM per accesso S3 ed ECR da K8s"
  sensitive   = true
}

variable "aws_region" {
  type        = string
  description = "Regione AWS"
  default     = "eu-south-1"
}
