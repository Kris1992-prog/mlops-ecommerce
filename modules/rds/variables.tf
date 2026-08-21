variable "environment" {
  type        = string
  description = "Ambiente di deployment"
  default     = "dev"
}

variable "vpc_id" {
  type        = string
  description = "ID della VPC"
}

variable "db_subnet_group_name" {
  type        = string
  description = "Nome del DB Subnet Group per isolare RDS nelle subnet private"
}

variable "web_security_group_id" {
  type        = string
  description = "ID del Security Group EC2 autorizzato a connettersi al DB"
}

variable "allocated_storage" {
  type        = number
  description = "Spazio disco allocato (in GB)"
  default     = 20
}

variable "instance_class" {
  type        = string
  description = "Classe d'istanza RDS"
  default     = "db.t3.micro"
}

variable "db_name" {
  type        = string
  description = "Nome del database"
  default     = "ecommercedb"
}

variable "db_username" {
  type        = string
  description = "Username utente master"
  default     = "kris_admin"
}

variable "db_password" {
  type        = string
  description = "Password master del DB"
  sensitive   = true
}

variable "db_backup_retention_days" {
  type        = number
  description = "Giorni di retention per i backup automatici RDS"
  default     = 1
}