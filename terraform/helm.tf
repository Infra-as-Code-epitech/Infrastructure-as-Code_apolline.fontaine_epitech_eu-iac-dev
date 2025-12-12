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

resource "helm_release" "cert-manager" {
  name             = "cert-manager-${var.env}"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.19.2"
  create_namespace = true
  namespace        = "cert-manager"

  set = [{
    name  = "crds.enabled"
    value = true
  }]
}


resource "helm_release" "github-runners" {
  name             = "github-runners-${var.env}"
  repository       = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart            = "actions-runner-controller"
  version          = "0.23.7"
  create_namespace = true
  namespace        = "runners"

  depends_on = [helm_release.cert-manager]
}

resource "helm_release" "app" {
  name      = var.helm_release_name
  chart     = var.helm_chart_path
  namespace = var.kubernetes_app_namespace

  create_namespace = true

  values = [
    file(var.helm_values_path)
  ]

  wait    = true
  timeout = 300
}

