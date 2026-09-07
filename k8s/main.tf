locals {
  app_label      = "ecommerce-${var.environment}"
  app_image_full = "${var.app_image}:${var.app_image_tag}"
  app_port       = 80
  ml_namespace   = "ml"
}

# ------------------------------------------------------------------------------
# Namespace ML
# ------------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "ml" {
  metadata {
    name = local.ml_namespace
  }
}

# ------------------------------------------------------------------------------
# Helm Release — Nginx Ingress Controller
# ------------------------------------------------------------------------------
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx-${var.environment}"
  chart            = var.helm_chart_path
  namespace        = "ingress-nginx"
  create_namespace = true

  wait            = false
  timeout         = 900
  cleanup_on_fail = true

  set = [
    {
      name  = "controller.admissionWebhooks.enabled"
      value = "false"
      type  = "string"
    }
  ]
}

# ------------------------------------------------------------------------------
# ECR imagePullSecret (condiviso da tutti i Deployment che usano ECR)
# ------------------------------------------------------------------------------
resource "kubernetes_secret_v1" "ecr_pull_secret" {
  metadata {
    name      = "ecr-pull-secret"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://${var.ecr_registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com" = {
          username = "AWS"
          password = var.ml_aws_secret_access_key
          auth     = base64encode("AWS:${var.ml_aws_secret_access_key}")
        }
      }
    })
  }
  type = "kubernetes.io/dockerconfigjson"
}

# ------------------------------------------------------------------------------
# MySQL locale
# ------------------------------------------------------------------------------
resource "kubernetes_secret_v1" "mysql_credentials" {
  metadata {
    name      = "mysql-credentials"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  data = {
    MYSQL_ROOT_PASSWORD = var.mysql_root_password
    MYSQL_DATABASE      = var.mysql_database
    MYSQL_USER          = var.mysql_user
    MYSQL_PASSWORD      = var.mysql_password
  }
  type = "Opaque"
}

resource "kubernetes_persistent_volume_claim_v1" "mysql_pvc" {
  metadata {
    name      = "mysql-pvc"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = { storage = "1Gi" }
    }
  }
}

resource "kubernetes_deployment_v1" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
    labels    = { app = "mysql" }
  }
  spec {
    replicas = 1
    selector { match_labels = { app = "mysql" } }
    template {
      metadata { labels = { app = "mysql" } }
      spec {
        container {
          name              = "mysql"
          image             = "mysql:8.0"
          image_pull_policy = "IfNotPresent"
          port { container_port = 3306 }
          env_from {
            secret_ref { name = kubernetes_secret_v1.mysql_credentials.metadata[0].name }
          }
          volume_mount {
            name       = "mysql-data"
            mount_path = "/var/lib/mysql"
          }
          resources {
            requests = { cpu = "250m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
          readiness_probe {
            exec {
              command = ["mysqladmin", "ping", "-h", "localhost", "-uroot", "-p$(MYSQL_ROOT_PASSWORD)"]
            }
            initial_delay_seconds = 20
            period_seconds        = 10
            failure_threshold     = 3
          }
        }
        volume {
          name = "mysql-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.mysql_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "mysql" {
  metadata {
    name      = "mysql"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  spec {
    selector = { app = "mysql" }
    port {
      port        = 3306
      target_port = 3306
    }
    type = "ClusterIP"
  }
}

# ------------------------------------------------------------------------------
# E-commerce app
# ------------------------------------------------------------------------------
resource "kubernetes_config_map_v1" "db_config" {
  metadata {
    name = "db-config-${var.environment}"
  }
  data = {
    DB_HOST = "mysql.${local.ml_namespace}.svc.cluster.local"
    DB_NAME = var.mysql_database
  }
}

resource "kubernetes_secret_v1" "db_credentials" {
  metadata {
    name = "db-credentials-${var.environment}"
  }
  data = {
    DB_USER = var.mysql_user
    DB_PASS = var.mysql_password
  }
  type = "Opaque"
}

resource "kubernetes_deployment_v1" "ecommerce_deployment" {
  wait_for_rollout = false
  metadata {
    name   = "ecommerce-deployment-${var.environment}"
    labels = { app = local.app_label }
  }
  spec {
    replicas = var.app_replicas
    selector { match_labels = { app = local.app_label } }
    template {
      metadata { labels = { app = local.app_label } }
      spec {
        container {
          name              = "ecommerce-app"
          image             = local.app_image_full
          image_pull_policy = "IfNotPresent"
          port { container_port = local.app_port }
          resources {
            limits   = { cpu = "500m", memory = "512Mi" }
            requests = { cpu = "250m", memory = "256Mi" }
          }
          env {
            name = "DB_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.db_config.metadata[0].name
                key  = "DB_HOST"
              }
            }
          }
          env {
            name = "DB_NAME"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.db_config.metadata[0].name
                key  = "DB_NAME"
              }
            }
          }
          env {
            name = "DB_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.db_credentials.metadata[0].name
                key  = "DB_USER"
              }
            }
          }
          env {
            name = "DB_PASS"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.db_credentials.metadata[0].name
                key  = "DB_PASS"
              }
            }
          }
          readiness_probe {
            http_get { 
            path = "/"
            port = local.app_port 
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 2
          }
          liveness_probe {
            http_get { 
            path = "/"
            port = local.app_port 
            }
            initial_delay_seconds = 20
            period_seconds        = 20
            failure_threshold     = 3
          }
        }
      }
    }
  }
  depends_on = [kubernetes_deployment_v1.mysql]
}

resource "kubernetes_service_v1" "ecommerce_service" {
  metadata { name = "ecommerce-service-${var.environment}" }
  spec {
    type     = "NodePort"
    selector = { app = local.app_label }
    port {
      protocol    = "TCP"
      port        = local.app_port
      target_port = local.app_port
      node_port   = 30081
    }
  }
}

resource "kubernetes_ingress_v1" "ecommerce_ingress" {
  metadata {
    name        = "ecommerce-ingress-${var.environment}"
    annotations = { "nginx.ingress.kubernetes.io/rewrite-target" = "/" }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "ecommerce.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.ecommerce_service.metadata[0].name
              port { number = local.app_port }
            }
          }
        }
      }
    }
  }
}

# ------------------------------------------------------------------------------
# MLOps Recommendation Service
# ------------------------------------------------------------------------------
resource "kubernetes_secret_v1" "ml_config" {
  metadata {
    name      = "ml-config"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  data = {
    AWS_ACCESS_KEY_ID     = var.ml_aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.ml_aws_secret_access_key
    AWS_REGION            = var.aws_region
    S3_BUCKET             = "kris-ecommerce-ml-dev"
    S3_KEY                = "model.joblib"
  }
  type = "Opaque"
}

resource "kubernetes_deployment_v1" "recommendation_api" {
  metadata {
    name      = "recommendation-api"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  spec {
    replicas = 1
    selector { match_labels = { app = "recommendation-api" } }
    template {
      metadata { labels = { app = "recommendation-api" } }
      spec {
        image_pull_secrets {
          name = kubernetes_secret_v1.ecr_pull_secret.metadata[0].name
        }
        container {
          name              = "api"
          image             = var.ml_api_image
          image_pull_policy = "IfNotPresent"
          port { container_port = 8000 }
          
          # Variabili esistenti da secret
          env_from {
            secret_ref { name = kubernetes_secret_v1.ml_config.metadata[0].name }
          }

          # Aggiungiamo qui la variabile d'ambiente per Ollama
          env {
            name  = "OLLAMA_URL"
            value = "http://ollama.ml.svc.cluster.local:11434"
          }
          env {
            name  = "OLLAMA_MODEL"
            value = "phi3:mini"
          }
          
          resources {
            requests = { cpu = "250m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }

          liveness_probe {
            http_get { 
            path = "/health"
            port = 8000 
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            failure_threshold     = 3
          }
          readiness_probe {
            http_get { 
            path = "/ready"
            port = 8000 
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "recommendation_api" {
  metadata {
    name      = "recommendation-api"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  spec {
    selector = { app = "recommendation-api" }
   port { 
    port = 80 
    target_port = 8000 
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "recommendation_ingress" {
  metadata {
    name      = "recommendation-ingress"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
    annotations = { "nginx.ingress.kubernetes.io/rewrite-target" = "/" }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "rec.ecommerce.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.recommendation_api.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_cron_job_v1" "recommendation_retrain_cron" {
  metadata {
    name      = "recommendation-retrain-cron"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  spec {
    schedule           = "0 2 * * *"
    concurrency_policy = "Forbid"
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            restart_policy = "OnFailure"
            image_pull_secrets {
              name = kubernetes_secret_v1.ecr_pull_secret.metadata[0].name
            }
            container {
              name              = "retrainer"
              image             = var.ml_trainer_image
              image_pull_policy = "Always"
              env_from {
                secret_ref { name = kubernetes_secret_v1.ml_config.metadata[0].name }
              }
              resources {
                requests = { cpu = "500m", memory = "512Mi" }
                limits   = { cpu = "1000m", memory = "1Gi" }
              }
            }
          }
        }
      }
    }
  }
}

# ------------------------------------------------------------------------------
# Progetto 2 — Ollama LLM (phi3:mini su CPU)
# ------------------------------------------------------------------------------
resource "kubernetes_persistent_volume_claim_v1" "ollama_pvc" {
  metadata {
    name      = "ollama-pvc"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = { storage = "5Gi" }
    }
  }
}

resource "kubernetes_stateful_set_v1" "ollama" {
  metadata {
    name      = "ollama"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
    labels    = { app = "ollama" }
  }
  spec {
    service_name = "ollama"
    replicas     = 1
    selector { match_labels = { app = "ollama" } }
    template {
      metadata { labels = { app = "ollama" } }
      spec {
        init_container {
          name              = "pull-phi3-mini"
          image             = "ollama/ollama:latest"
          image_pull_policy = "IfNotPresent"
          command           = ["/bin/sh", "-c"]
          args              = ["ollama serve & sleep 3 && ollama pull phi3:mini"]
          env {
            name  = "OLLAMA_HOST"
            value = "0.0.0.0"
          }
          volume_mount {
            name      = "ollama-data"
            mount_path = "/root/.ollama"
          }
          resources {
            requests = { cpu = "500m", memory = "1Gi" }
            limits   = { cpu = "1000m", memory = "2Gi" }
          }
        }
        container {
          name              = "ollama"
          image             = "ollama/ollama:latest"
          image_pull_policy = "IfNotPresent"
          port { container_port = 11434 }
          env {
            name  = "OLLAMA_HOST"
            value = "0.0.0.0"
          }
          volume_mount {
            name       = "ollama-data"
            mount_path = "/root/.ollama"
          }
          resources {
            requests = { cpu = "500m", memory = "1Gi" }
            limits   = { cpu = "2000m", memory = "2Gi" }
          }
          readiness_probe {
            http_get { 
              path = "/api/tags" 
              port = 11434 
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            failure_threshold     = 5
          }
          liveness_probe {
            http_get { 
              path = "/api/tags" 
              port = 11434 
              }
            initial_delay_seconds = 60
            period_seconds        = 20
            failure_threshold     = 3
          }
        }
        volume {
          name = "ollama-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.ollama_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "ollama" {
  metadata {
    name      = "ollama"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  spec {
    selector = { app = "ollama" }
    port {
      port        = 11434
      target_port = 11434
    }
    type = "ClusterIP"
  }
}

# ------------------------------------------------------------------------------
# LLM Gateway (FastAPI → Ollama)
# ------------------------------------------------------------------------------
resource "kubernetes_config_map_v1" "llm_gateway_config" {
  metadata {
    name      = "llm-gateway-config"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  data = {
    OLLAMA_URL   = "http://ollama.${local.ml_namespace}.svc.cluster.local:11434"
    OLLAMA_MODEL = "phi3:mini"
  }
}

resource "kubernetes_deployment_v1" "llm_gateway" {
  metadata {
    name      = "llm-gateway"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
    labels    = { app = "llm-gateway" }
  }
  spec {
    replicas = 1
    selector { match_labels = { app = "llm-gateway" } }
    template {
      metadata { labels = { app = "llm-gateway" } }
      spec {
        image_pull_secrets {
          name = kubernetes_secret_v1.ecr_pull_secret.metadata[0].name
        }
        container {
          name              = "gateway"
          image             = var.llm_gateway_image
          image_pull_policy = "Always"
          port { container_port = 8001 }
          env_from {
            config_map_ref { name = kubernetes_config_map_v1.llm_gateway_config.metadata[0].name }
          }
          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
          liveness_probe {
            http_get { 
              path = "/health" 
              port = 8001 
              }
            initial_delay_seconds = 10
            period_seconds        = 10
            failure_threshold     = 3
          }
          readiness_probe {
            http_get { 
              path = "/ready" 
              port = 8001 
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }
  depends_on = [kubernetes_stateful_set_v1.ollama]
}

resource "kubernetes_service_v1" "llm_gateway" {
  metadata {
    name      = "llm-gateway"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  spec {
    selector = { app = "llm-gateway" }
    port {
      port        = 80
      target_port = 8001
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "llm_gateway_ingress" {
  metadata {
    name      = "llm-gateway-ingress"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
    annotations = { "nginx.ingress.kubernetes.io/rewrite-target" = "/" }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "llm.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.llm_gateway.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "llm_gateway_hpa" {
  metadata {
    name      = "llm-gateway-hpa"
    namespace = kubernetes_namespace_v1.ml.metadata[0].name
  }
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.llm_gateway.metadata[0].name
    }
    min_replicas = 1
    max_replicas = 3
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 60
        }
      }
    }
  }
}
