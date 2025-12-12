output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "The ID of the Subnet"
  value       = aws_subnet.subnet1.id
}

output "helm_release_status" {
  description = "Statut de la release Helm"
  value       = helm_release.app.status
}

output "helm_release_version" {
  description = "Version déployée de la release Helm"
  value       = helm_release.app.version
}
