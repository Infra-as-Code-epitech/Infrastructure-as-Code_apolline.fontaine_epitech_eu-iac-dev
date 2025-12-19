resource "helm_release" "app" {
  name      = var.helm_release_name
  chart     = var.helm_chart_path
  namespace = var.kubernetes_app_namespace

  create_namespace = true

  values = [
    file(var.helm_values_path)
  ]

  replace = true
  wait    = true
  timeout = 300
}
