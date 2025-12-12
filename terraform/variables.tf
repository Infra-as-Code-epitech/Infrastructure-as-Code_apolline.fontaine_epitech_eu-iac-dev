variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "vpc"
}

variable "eks_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks"
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    environment = "dev"
    Name        = "infraascode-vpc"
  }
}

variable "cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
  default     = "my-cluster"
}

variable "helm_release_name" {
  description = "Nom de la release Helm"
  type        = string
  default     = "app"
}

variable "helm_chart_path" {
  description = "Chemin vers le chart Helm (local ou distant)"
  type        = string
  default     = "../helm"
}

variable "helm_values_path" {
  description = "Chemin vers le fichier values.yaml"
  type        = string
  default     = "../helm/values.yaml"
}

variable "kubernetes_namespace" {
  description = "Namespace Kubernetes pour déployer l'application"
  type        = string
  default     = "default"
}

