output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "configure_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "helm_values_file" {
  description = "Path to Helm values file with cluster information"
  value       = "See ../helm/httpbin-app/values.yaml for application deployment"
}

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value       = <<-EOT
    Infrastructure deployed successfully!
    
    Next steps:
    1. Configure kubectl:
       ${module.eks.cluster_name != "" ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}" : ""}
    
    2. Verify cluster access:
       kubectl get nodes
    
    3. Deploy application using Helm:
       cd ../helm
       helm install httpbin httpbin-app/ -n httpbin --create-namespace
    
    4. Check deployment:
       kubectl get pods -n httpbin
       kubectl get ingress -n httpbin
  EOT
}
