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

resource "kubernetes_manifest" "adot_collector" {
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
