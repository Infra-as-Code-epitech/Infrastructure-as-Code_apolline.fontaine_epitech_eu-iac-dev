resource "helm_release" "app" {
  name      = var.helm_release_name
  chart     = var.helm_chart_path
  namespace = var.kubernetes_app_namespace

  create_namespace = true

  values = [
    file(var.helm_values_path)
  ]

  wait            = true
  timeout         = 900
  wait_for_jobs   = true
  atomic          = false
  cleanup_on_fail = true

  depends_on = [
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster
  ]
}
