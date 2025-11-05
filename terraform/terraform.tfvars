# Example Terraform variables
# Copy this file to terraform.tfvars and customize as needed

aws_region = "us-east-1"
project_name = "etpa-k8s"
environment = "dev"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# EKS Configuration
cluster_version = "1.33"
instance_types = ["t3.medium"]
desired_capacity = 1
min_capacity = 1
max_capacity = 4
enable_cluster_autoscaler = true

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "terraform"
  Project     = "ETPA-K8S"
  CostCenter  = "engineering"
  Owner       = "devops-team"
}
