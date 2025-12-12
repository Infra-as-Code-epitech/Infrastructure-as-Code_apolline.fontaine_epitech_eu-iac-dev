region   = "eu-west-1"
vpc_name = "dev-vpc"

cluster_name         = "eks-dev"
helm_release_name    = "app"
helm_chart_path      = "../helm"
helm_values_path     = "../helm/values.yaml"
kubernetes_namespace = "default"

tags = {
  environment = "dev"
  project     = "my-project"
}
