variable "environment" {
  type        = string
  description = "Nome dell'ambiente"
  default     = "dev"
}

variable "app_image_tag" {
  type        = string
  description = "Tag dell'immagine Docker dell'app e-commerce"
  default     = "latest"
}

variable "helm_chart_path" {
  type        = string
  description = "Path relativo al pacchetto del chart Helm per ingress-nginx"
  default     = "../../ingress-nginx-4.15.1.tgz"
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

variable "aws_region" {
  type        = string
  description = "Regione AWS di riferimento"
  default     = "eu-south-1"
}

variable "app_image" {
  type    = string
  description = "Immagine Docker per l'applicazione"
}

variable "app_replicas" {
  type    = number
  description = "Numero di repliche per i pod"
  default = 1
}

variable "admin_cidr" {
  type        = string
  description = "CIDR block autorizzato per l'accesso amministrativo"
  default     = "0.0.0.0/0" # o il valore specifico che usi di solito
}