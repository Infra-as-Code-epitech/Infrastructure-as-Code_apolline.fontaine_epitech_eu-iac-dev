terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  required_version = ">= 1.14"

  backend "s3" {
    bucket = ""
    key    = "state/terraform.tfstate"
    region = ""
  }

}
