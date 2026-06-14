output "namespace" {
  description = "Namespace where Terraform deployed the application."
  value       = var.namespace
}

output "app_service_name" {
  description = "Kubernetes Service name for the web application."
  value       = local.app_service_name
}

output "mongodb_service_name" {
  description = "Kubernetes Service name for MongoDB."
  value       = local.mongo_service_name
}

output "port_forward_command" {
  description = "Command to open the Terraform-deployed app locally."
  value       = "kubectl -n ${var.namespace} port-forward service/${local.app_service_name} 3000:80"
}

output "local_url" {
  description = "URL to use after running the port-forward command."
  value       = "http://127.0.0.1:3000"
}

output "ingress_url" {
  description = "Ingress URL when enable_ingress is true."
  value       = var.enable_ingress ? "https://${var.ingress_host}" : null
}
