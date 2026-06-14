output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint."
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Command to configure kubectl for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "deploy_application" {
  description = "Command to deploy the app with Terraform after pushing an image and preparing terraform/app/production.tfvars."
  value       = "cd ../app && terraform init && terraform apply -var-file=production.tfvars"
}
