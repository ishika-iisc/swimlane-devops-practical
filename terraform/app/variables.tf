variable "kubeconfig_path" {
  description = "Path to the kubeconfig Terraform should use."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Optional kubeconfig context to use. Leave null to use the current context."
  type        = string
  default     = null
}

variable "namespace" {
  description = "Kubernetes namespace for the application."
  type        = string
  default     = "swimlane"
}

variable "app_name" {
  description = "Application name used in Kubernetes labels."
  type        = string
  default     = "swimlane-devops-practical"
}

variable "extra_labels" {
  description = "Additional labels to attach to managed resources."
  type        = map(string)
  default     = {}
}

variable "node_env" {
  description = "NODE_ENV value for the application container."
  type        = string
  default     = "production"
}

variable "app_image" {
  description = "Container image for the Node.js application."
  type        = string
  default     = "ghcr.io/your-github-user/swimlane-devops-practical:1.0.0"
}

variable "app_image_pull_policy" {
  description = "Image pull policy for the application container."
  type        = string
  default     = "IfNotPresent"

  validation {
    condition     = contains(["Always", "IfNotPresent", "Never"], var.app_image_pull_policy)
    error_message = "app_image_pull_policy must be Always, IfNotPresent, or Never."
  }
}

variable "app_replicas" {
  description = "Desired number of application replicas."
  type        = number
  default     = 2
}

variable "app_min_replicas" {
  description = "Minimum application replicas for the HPA."
  type        = number
  default     = 2
}

variable "app_max_replicas" {
  description = "Maximum application replicas for the HPA."
  type        = number
  default     = 6
}

variable "app_cpu_request" {
  description = "Application CPU request."
  type        = string
  default     = "100m"
}

variable "app_memory_request" {
  description = "Application memory request."
  type        = string
  default     = "256Mi"
}

variable "app_cpu_limit" {
  description = "Application CPU limit."
  type        = string
  default     = "500m"
}

variable "app_memory_limit" {
  description = "Application memory limit."
  type        = string
  default     = "512Mi"
}

variable "mongo_image" {
  description = "MongoDB container image."
  type        = string
  default     = "mongo:7.0"
}

variable "mongo_storage_size" {
  description = "Persistent volume size for MongoDB."
  type        = string
  default     = "10Gi"
}

variable "mongo_storage_class_name" {
  description = "Optional StorageClass for the MongoDB PVC. Leave null for the cluster default."
  type        = string
  default     = null
}

variable "mongo_root_username" {
  description = "MongoDB root username."
  type        = string
  default     = "root"
}

variable "mongo_root_password" {
  description = "MongoDB root password. Override for any non-demo deployment."
  type        = string
  default     = "change-me-root"
  sensitive   = true
}

variable "mongo_app_database" {
  description = "MongoDB database used by the application."
  type        = string
  default     = "swimlane"
}

variable "mongo_app_username" {
  description = "MongoDB application username."
  type        = string
  default     = "swimlane"
}

variable "mongo_app_password" {
  description = "MongoDB application password. Override for any non-demo deployment."
  type        = string
  default     = "change-me-app"
  sensitive   = true
}

variable "enable_network_policy" {
  description = "Create NetworkPolicies for app-to-MongoDB and DNS traffic."
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Create an Ingress for the application."
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Host name for the optional application Ingress."
  type        = string
  default     = "swimlane.example.com"
}

variable "ingress_class_name" {
  description = "IngressClass name for the optional application Ingress."
  type        = string
  default     = "nginx"
}

variable "ingress_tls_secret_name" {
  description = "Optional TLS Secret name for the application Ingress."
  type        = string
  default     = "swimlane-tls"
}

variable "ingress_annotations" {
  description = "Additional annotations for the optional application Ingress."
  type        = map(string)
  default     = {}
}
