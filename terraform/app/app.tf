resource "helm_release" "app" {
  name      = var.helm_release_name
  chart     = var.helm_chart_path
  namespace = "app"

  create_namespace = true
  upgrade_install  = true

  values = [
    file(var.helm_values_path)
  ]

  set = [
    {
      name  = "image.repository"
      value = aws_ecr_repository.api.repository_url
    },
    {
      name  = "image.tag"
      value = var.image_tag
    }
  ]

  wait            = true
  timeout         = 300
  wait_for_jobs   = true
  atomic          = false
  cleanup_on_fail = true
  force_update    = true
  reuse_values    = true

  depends_on = [
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster,
    null_resource.docker_build_push
  ]
}
