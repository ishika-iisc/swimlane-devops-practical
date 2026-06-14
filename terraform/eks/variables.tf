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
}

variable "public_subnets" {
  description = "Public subnet CIDRs, one per AZ."
  type        = list(string)
  default     = ["10.42.101.0/24", "10.42.102.0/24", "10.42.103.0/24"]
}

variable "node_instance_types" {
  description = "EC2 instance types for managed worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Restrict this for production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
