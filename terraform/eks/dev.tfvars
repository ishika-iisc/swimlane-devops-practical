aws_region      = "us-east-1"
project_name    = "swimlane-practical"
environment     = "dev"
cluster_name    = "swimlane-practical"
cluster_version = "1.30"

vpc_cidr        = "10.42.0.0/16"
private_subnets = ["10.42.1.0/24", "10.42.2.0/24", "10.42.3.0/24"]
public_subnets  = ["10.42.101.0/24", "10.42.102.0/24", "10.42.103.0/24"]

cluster_log_retention_days      = 30
cluster_endpoint_private_access = true

ecr_repository_name      = "swimlane-practical-dev"
ecr_image_tag_mutability = "MUTABLE"
ecr_force_delete         = true

node_instance_types = ["t3.medium"]
node_ami_type       = "AL2_x86_64"
node_min_size       = 3
node_max_size       = 6
node_desired_size   = 3

cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
