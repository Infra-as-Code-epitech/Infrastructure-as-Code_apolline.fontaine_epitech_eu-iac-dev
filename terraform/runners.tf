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

data "aws_secretsmanager_secret" "github_app_key" {
  name = "github-runners/app/key"
}

data "aws_secretsmanager_secret_version" "github_app_key" {
  secret_id = data.aws_secretsmanager_secret.github_app_key.id
}

resource "helm_release" "arc_controller" {
  name             = "arc"
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set-controller"
  version          = "0.13.0"
  namespace        = "runners"
  create_namespace = true
  replace          = true
  wait             = true
}

resource "helm_release" "arc_runner_scale_set" {
  name             = "arc-runner-set"
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set"
  version          = "0.13.0"
  namespace        = "runners"
  create_namespace = true
  wait             = true
  replace          = true
  depends_on       = [helm_release.arc_controller]
  set = [
    {
      name  = "githubConfigUrl"
      value = "https://github.com/Infra-as-Code-epitech/Infrastructure-as-Code_apolline.fontaine_epitech_eu-iac-dev.git"
    },
    {
      name  = "minRunners"
      value = "1"
    },
    {
      name  = "maxRunners"
      value = "3"
    },
    {
      name  = "githubConfigSecret.github_app_id"
      value = "2459522"
    },
    {
      name  = "githubConfigSecret.github_app_installation_id"
      value = "99261673"
    },
    {
      name  = "containerMode.type"
      value = "dind"
    }
  ]

  set_sensitive = [
    {
      name  = "githubConfigSecret.github_app_private_key"
      value = data.aws_secretsmanager_secret_version.github_app_key.secret_string
    }
  ]
}
