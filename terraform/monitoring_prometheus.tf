variable "kube_prometheus_stack_version" {
  type    = string
  default = "80.2.2"
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-${var.env}"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version

  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  depends_on = [
    kubernetes_namespace_v1.monitoring,
    module.eks-managed-node-group
  ]
}
