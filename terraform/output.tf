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

output "eks_security_group_id" {
  description = "Security group ids attached to the EKS cluster control plane"
  value       = module.eks-managed-node-group.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

# output "helm_release_status" {
#   description = "Statut de la release Helm"
#   value       = helm_release.app.status
# }

# output "helm_release_version" {
#   description = "Version déployée de la release Helm"
#   value       = helm_release.app.version
# }
