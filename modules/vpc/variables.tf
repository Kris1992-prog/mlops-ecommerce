variable "environment" {
  type        = string
  description = "Ambiente di deployment (es. dev, prod)"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block per la VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Lista dei CIDR per le subnet pubbliche"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Lista dei CIDR per le subnet private"
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability Zone da utilizzare in eu-south-1"
  default     = ["eu-south-1a", "eu-south-1b"]
}