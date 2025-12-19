region = "eu-west-1"
tags = {
  "environment" = "prd"
}
vpc_name          = "vpc-prd"
eks_name          = "eks-prd"
env               = "prd"
helm_release_name = "app"
helm_chart_path   = "../helm"
helm_values_path  = "../helm/values.yaml"
