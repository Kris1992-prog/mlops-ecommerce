output "deployment_name" {
  description = "Nome del deployment Kubernetes"
  value       = kubernetes_deployment_v1.ecommerce_deployment.metadata[0].name
}

output "service_name" {
  description = "Nome del service Kubernetes"
  value       = kubernetes_service_v1.ecommerce_service.metadata[0].name
}