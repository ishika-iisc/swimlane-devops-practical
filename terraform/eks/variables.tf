variable "aws_region" {
  description = "AWS region used for the EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used for AWS resource tags and names."
  type        = string
  default     = "swimlane-practical"
}

variable "environment" {
  description = "Environment tag."
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "swimlane-practical"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS."
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "private_subnets" {
  description = "Private subnet CIDRs, one per AZ."
  type        = list(string)
  default     = ["10.42.1.0/24", "10.42.2.0/24", "10.42.3.0/24"]

  validation {
    condition     = length(var.private_subnets) >= 2
    error_message = "private_subnets must contain at least two CIDR blocks for high availability."
  }
}

variable "public_subnets" {
  description = "Public subnet CIDRs, one per AZ."
  type        = list(string)
  default     = ["10.42.101.0/24", "10.42.102.0/24", "10.42.103.0/24"]
}

variable "cluster_log_retention_days" {
  description = "Retention period for EKS control-plane logs."
  type        = number
  default     = 30
}

variable "cluster_endpoint_private_access" {
  description = "Whether the EKS API endpoint is reachable from inside the VPC."
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "EC2 instance types for managed worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_ami_type" {
  description = "AMI type for the EKS managed node group."
  type        = string
  default     = "AL2_x86_64"
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 6
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 3
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Restrict this for production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_admin_principal_arns" {
  description = "IAM user or role ARNs that should receive cluster-admin access through EKS access entries."
  type        = list(string)
  default     = []
}

variable "cluster_viewer_principal_arns" {
  description = "IAM user or role ARNs that should receive read-only Kubernetes visibility through EKS access entries."
  type        = list(string)
  default     = []
}
