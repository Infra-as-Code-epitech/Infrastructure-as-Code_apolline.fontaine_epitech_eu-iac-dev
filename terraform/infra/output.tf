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

output "rds_master_secret_name" {
  description = "Name of the RDS master password secret in AWS Secrets Manager"
  value       = aws_db_instance.rds.master_user_secret[0].secret_arn
}
