provider "aws" {
  region = var.region
}

data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = var.bucket_name
    key    = "infra/terraform.tfstate"
    region = var.region
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.infra.outputs.eks_name
}

provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.infra.outputs.eks_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
