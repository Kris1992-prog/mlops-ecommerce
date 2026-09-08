module "ml_infra" {
  source      = "../../modules/ml-service"
  bucket_name = "kris-ecommerce-ml-dev"
  environment = var.environment
}

# ------------------------------------------------------------------------------
# Import delle risorse AWS esistenti nello stato di Terraform
# ------------------------------------------------------------------------------
import {
  to = module.ml_infra.aws_s3_bucket.ml_models
  id = "kris-ecommerce-ml-dev"
}

import {
  to = module.ml_infra.aws_ecr_repository.ml_api
  id = "ml-recommendations-api"
}

import {
  to = module.ml_infra.aws_ecr_repository.ml_trainer
  id = "ml-recommendations-trainer"
}

import {
  to = module.ml_infra.aws_ecr_repository.llm_gateway
  id = "llm-gateway"
}

import {
  to = module.ml_infra.aws_iam_user.k8s_ml_user
  id = "k8s-mlops-s3-user-dev"
}

# ------------------------------------------------------------------------------
# Modulo Kubernetes
# ------------------------------------------------------------------------------
module "k8s" {
  source          = "../../k8s"
  environment     = var.environment
  app_image_tag   = var.app_image_tag
  helm_chart_path = var.helm_chart_path

  ml_api_image      = "${module.ml_infra.ecr_ml_api_url}:latest"
  ml_trainer_image  = "${module.ml_infra.ecr_ml_trainer_url}:latest"
  llm_gateway_image = "${module.ml_infra.ecr_llm_gateway_url}:latest"

  ecr_registry_id           = module.ml_infra.ecr_registry_id
  ml_aws_access_key_id     = module.ml_infra.aws_access_key_id
  ml_aws_secret_access_key = module.ml_infra.aws_secret_access_key

  mysql_root_password = var.mysql_root_password
  mysql_database      = var.mysql_database
  mysql_user          = var.mysql_user
  mysql_password      = var.mysql_password

  depends_on = [module.ml_infra]
}