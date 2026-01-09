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
    env  = "dev"
    Name = "infraascode-vpc"
  }
}

variable "image_tag" {
  description = "Tag de l'image Docker à déployer"
  type        = string
  default     = "latest"
}
