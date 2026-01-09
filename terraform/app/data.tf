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
