data "aws_eks_cluster" "cluster" {
  name       = module.eks-managed-node-group.cluster_name
  depends_on = [module.eks-managed-node-group]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks-managed-node-group.cluster_name
  depends_on = [module.eks-managed-node-group]
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "app" {
  name      = var.helm_release_name
  chart     = var.helm_chart_path
  namespace = var.kubernetes_app_namespace

  create_namespace = true

  values = [
    file(var.helm_values_path)
  ]

  wait                  = true
  timeout               = 900
  wait_for_jobs         = true
  atomic                = false

  depends_on = [
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster
  ]
}
