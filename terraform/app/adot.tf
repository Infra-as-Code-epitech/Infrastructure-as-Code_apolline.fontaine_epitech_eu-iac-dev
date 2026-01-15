resource "kubernetes_namespace_v1" "observability" {
  metadata {
    name = "observability"
  }
}

resource "kubernetes_service_account_v1" "adot" {
  metadata {
    name      = "observability-sa"
    namespace = "observability"
  }
  depends_on = [kubernetes_namespace_v1.observability]
}

resource "kubernetes_cluster_role_v1" "adot" {
  metadata {
    name = "adot-collector"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "pods", "endpoints", "services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "adot" {
  metadata {
    name = "adot-collector"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.adot.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.adot.metadata[0].name
    namespace = kubernetes_service_account_v1.adot.metadata[0].namespace
  }
}

resource "kubernetes_manifest" "adot_collector" {
  computed_fields = ["spec.config"]
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "OpenTelemetryCollector"
    metadata = {
      name      = "adot"
      namespace = "observability"
    }
    spec = {
      mode           = "daemonset"
      serviceAccount = "observability-sa"
      config = templatefile("${path.module}/../../otel/adot-config.yaml", {
        amp_endpoint = data.terraform_remote_state.infra.outputs.amp_endpoint
        region       = var.region
      })
    }
  }
  depends_on = [
    kubernetes_namespace_v1.observability,
    kubernetes_service_account_v1.adot
  ]
}
