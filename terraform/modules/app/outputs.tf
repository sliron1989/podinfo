output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = kubernetes_deployment_v1.app.metadata[0].name
}

output "service_name" {
  description = "Name of the Kubernetes service"
  value       = kubernetes_service_v1.app.metadata[0].name
}

output "hostname" {
  description = "Ingress hostname for this application"
  value       = var.hostname
}
