region = "eu-west-1"
tags = {
  "environment" = "dev"
}
vpc_name             = "vpc-dev"
eks_name             = "eks-dev"
env                  = "dev"
helm_release_name    = "app"
helm_chart_path      = "../helm"
helm_values_path     = "../helm/values.yaml"
kubernetes_namespace = "app"
