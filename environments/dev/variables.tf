variable "aws_region" {
  type        = string
  description = "Regione AWS"
  default     = "eu-south-1"
}

variable "environment" {
  type        = string
  description = "Nome dell'ambiente"
  default     = "dev"
}

variable "app_image_tag" {
  type        = string
  description = "Tag dell'immagine Docker da deployare"
  default     = "latest"
}

variable "helm_chart_path" {
  type        = string
  description = "Path relativo al pacchetto del chart Helm per ingress-nginx"
  default     = "../../ingress-nginx-4.15.1.tgz"
}

variable "admin_cidr" {
  type        = string
  description = "CIDR IP dell'amministratore autorizzato all'accesso SSH"
  default     = "0.0.0.0/0" # Oppure inserisci il tuo IP specifico seguito da /32
}