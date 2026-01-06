variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "env" {
  description = "Environment name"
  type        = string
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

variable "image_tag" {
  description = "Tag de l'image Docker à déployer"
  type        = string
  default     = "latest"
}
