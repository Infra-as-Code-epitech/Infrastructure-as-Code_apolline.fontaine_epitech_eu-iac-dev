output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "subnet_id" {
  description = "The ID of the Subnet"
  value       = module.vpc.public_subnets
}

output "eks_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks-managed-node-group.cluster_endpoint
}

output "eks_name" {
  description = "EKS Cluster name"
  value       = module.eks-managed-node-group.cluster_name
}

output "cluster_certificate_authority_data" {
  value = module.eks-managed-node-group.cluster_certificate_authority_data
}

output "eks_security_group_id" {
  description = "Security group ids attached to the EKS cluster control plane"
  value       = module.eks-managed-node-group.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "ecr_repository_url" {
  description = "URL du repository ECR"
  value       = aws_ecr_repository.api.repository_url
}
