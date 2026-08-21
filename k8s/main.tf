locals {
  app_label      = "ecommerce-${var.environment}"
  app_image_full = "${var.app_image}:${var.app_image_tag}"
  app_port       = 80
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
# Resources Kubernetes
# ------------------------------------------------------------------------------

resource "kubernetes_config_map_v1" "db_config" {
  metadata {
    name = "db-config-${var.environment}"
  }

  data = {
    DB_HOST = var.db_host
    DB_NAME = var.db_name
  }
}

resource "kubernetes_secret_v1" "db_credentials" {
  metadata {
    name = "db-credentials-${var.environment}"
  }

  data = {
    DB_USER = var.db_username
    DB_PASS = var.db_password
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

    selector {
      match_labels = { app = local.app_label }
    }

    template {
      metadata {
        labels = { app = local.app_label }
      }

      spec {
        container {
          name              = "ecommerce-app"
          image             = local.app_image_full
          image_pull_policy = "IfNotPresent"

          port {
            container_port = local.app_port
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
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
}

resource "kubernetes_service_v1" "ecommerce_service" {
  metadata {
    name = "ecommerce-service-${var.environment}"
  }

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
              port {
                number = local.app_port
              }
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

resource "kubernetes_secret_v1" "ml_s3_credentials" {
  metadata {
    name = "ml-s3-credentials"
  }

  data = {
    AWS_ACCESS_KEY_ID     = var.ml_aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.ml_aws_secret_access_key
    AWS_REGION            = "eu-west-1"
    S3_BUCKET             = "kris-ecommerce-ml-dev"
    S3_KEY                = "recommendation/model.joblib"
  }

  type = "Opaque"
}

resource "kubernetes_deployment_v1" "recommendation_api" {
  metadata {
    name = "recommendation-api"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "recommendation-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "recommendation-api"
        }
      }

      spec {
        container {
          name              = "api"
          image             = "recommendation-api:v1.0.0"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 8000
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.ml_s3_credentials.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "recommendation_api" {
  metadata {
    name = "recommendation-api"
  }

  spec {
    selector = {
      app = "recommendation-api"
    }

    port {
      port        = 8000
      target_port = 8000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_cron_job_v1" "recommendation_retrain_cron" {
  metadata {
    name = "recommendation-retrain-cron"
  }

  spec {
    schedule           = "0 2 * * 0"
    concurrency_policy = "Forbid"

    job_template {
      metadata {}

      spec {
        template {
          metadata {}

          spec {
            restart_policy = "OnFailure"

            container {
              name              = "retrainer"
              image             = "recommendation-retrain:v1.0.0"
              image_pull_policy = "IfNotPresent"

              env_from {
                secret_ref {
                  name = kubernetes_secret_v1.ml_s3_credentials.metadata[0].name
                }
              }

              resources {
                requests = {
                  cpu    = "500m"
                  memory = "512Mi"
                }
                limits = {
                  cpu    = "1000m"
                  memory = "1Gi"
                }
              }
            }
          }
        }
      }
    }
  }
}