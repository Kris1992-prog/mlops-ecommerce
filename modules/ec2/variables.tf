variable "environment" {
  type        = string
  description = "Ambiente di deployment"
  default     = "dev"
}

variable "vpc_id" {
  type        = string
  description = "ID della VPC"
}

variable "public_subnet_id" {
  type        = string
  description = "ID della subnet pubblica per l'istanza EC2"
}

variable "admin_cidr" {
  type        = string
  description = "CIDR autorizzato per l'accesso SSH"
}

variable "instance_type" {
  type        = string
  description = "Tipo di istanza EC2"
  default     = "t3.micro"
}

variable "ec2_key_name" {
  type        = string
  description = "Nome della key pair EC2 per accesso SSH"
  default     = "MioServerKeyMilano"
}

variable "elastic_ip" {
  type        = string
  description = "Elastic IP pubblico pre-allocato"
  default     = "18.102.134.191"
}

variable "app_repo_url" {
  type        = string
  description = "URL del repository Git"
  default     = "https://github.com/Kris1992-prog/progetto-ecommerce.git"
}

variable "db_host" {
  type        = string
  description = "Endpoint/Address del DB RDS MySQL"
}

variable "db_username" {
  type        = string
  description = "Username DB"
}

variable "db_password" {
  type        = string
  description = "Password DB"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Nome del database"
}