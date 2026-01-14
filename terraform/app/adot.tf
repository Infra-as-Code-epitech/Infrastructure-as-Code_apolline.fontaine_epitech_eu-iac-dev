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

resource "kubernetes_cluster_role_v1" "adot_permissions" {
  metadata {
    name = "adot-collector-role"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "nodes", "namespaces", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes/stats", "nodes/proxy"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [kubernetes_service_account_v1.adot]
}

resource "kubernetes_cluster_role_binding_v1" "adot_binding" {
  metadata {
    name = "adot-collector-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.adot_permissions.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "observability-sa"
    namespace = "observability"
  }

  depends_on = [kubernetes_service_account_v1.adot]
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

resource "kubernetes_manifest" "adot_instrumentation" {
  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind       = "Instrumentation"
    metadata = {
      name      = "adot-instrumentation"
      namespace = "observability"
    }
    spec = {
      exporter = {
        endpoint = "http://adot-collector.observability.svc.cluster.local:4317"
      }
      propagators = ["tracecontext", "baggage", "b3"]
      sampler = {
        type     = "parentbased_traceidratio"
        argument = "1"
      }
      python = {
        env = [
          {
            name  = "OTEL_PYTHON_LOG_CORRELATION"
            value = "true"
          }
        ]
      }
    }
  }

  depends_on = [kubernetes_namespace_v1.observability]
}
