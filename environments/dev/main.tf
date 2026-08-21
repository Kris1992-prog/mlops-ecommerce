# 1. Modulo Secrets Manager
module "secrets" {
  source      = "../../modules/secrets"
  environment = var.environment
  db_username = "kris_admin"
}

# 2. Modulo VPC
module "vpc" {
  source      = "../../modules/vpc"
  environment = var.environment
}

# 3. Modulo S3
module "s3" {
  source      = "../../modules/s3"
  environment = var.environment
}

# 4. Modulo EC2
module "ec2" {
  source           = "../../modules/ec2"
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
  admin_cidr       = var.admin_cidr
  db_host          = module.rds.db_address
  db_username      = "kris_admin"
  db_password      = module.secrets.db_password
  db_name          = module.rds.db_name
}

# 5. Modulo RDS
module "rds" {
  source                = "../../modules/rds"
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  db_subnet_group_name  = module.vpc.db_subnet_group_name
  web_security_group_id = module.ec2.security_group_id
  db_username           = "kris_admin"
  db_password           = module.secrets.db_password
}

# 6. Modulo Infrastructure ML AWS
module "recommendation_ml_infra" {
  source      = "../../modules/ml-service"
  bucket_name = "kris-ecommerce-ml-dev"
  region      = var.aws_region
  environment = var.environment
}

# 7. Modulo Kubernetes (Tutto il cluster k8s + Microservizio ML)
module "k8s" {
  source          = "../../k8s"
  environment     = var.environment
  db_host         = module.rds.db_address
  db_name         = module.rds.db_name
  db_username     = "kris_admin"
  db_password     = module.secrets.db_password
  app_image_tag   = var.app_image_tag
  helm_chart_path = var.helm_chart_path

  # Iniezione automatica delle credenziali prodotte dal modulo ML
  ml_aws_access_key_id     = module.recommendation_ml_infra.aws_access_key_id
  ml_aws_secret_access_key = module.recommendation_ml_infra.aws_secret_access_key

  depends_on = [module.ec2, module.rds, module.recommendation_ml_infra]
}