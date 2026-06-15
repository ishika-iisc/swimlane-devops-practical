aws_region     = "us-east-1"
project_name   = "swimlane-practical"
environment    = "prod"
cluster_name   = "swimlane-practical-prod"
cluster_version = "1.35"

vpc_cidr        = "10.150.0.0/16"
private_subnets = ["10.150.1.0/24", "10.150.2.0/24", "10.150.3.0/24"]
public_subnets  = ["10.150.101.0/24", "10.150.102.0/24", "10.150.103.0/24"]

cluster_log_retention_days      = 90
cluster_endpoint_private_access = true

node_instance_types = ["t3.small"]
node_ami_type       = "AL2023_x86_64_STANDARD"
node_min_size       = 2
node_max_size       = 10
node_desired_size   = 3

cluster_endpoint_public_access_cidrs = ["134.231.163.196/32"]
