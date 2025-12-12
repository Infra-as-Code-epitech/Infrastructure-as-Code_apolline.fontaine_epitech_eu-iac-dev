terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  
  required_version = ">= 1.2"

  backend "s3" {
    bucket = ""
    key    = "state/terraform.tfstate"
    region = ""
  }
  
}
