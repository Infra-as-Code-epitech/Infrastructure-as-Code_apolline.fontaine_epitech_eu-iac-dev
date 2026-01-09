resource "helm_release" "opentelemetry_operator" {
  name       = "opentelemetry-operator"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-operator"
  namespace  = "opentelemetry-operator-system"
  version    = "0.47.0"
  
  create_namespace = true
  
  set {
    name  = "manager.collectorImage.repository"
    value = "otel/opentelemetry-collector-k8s"
  }
}

resource "helm_release" "otel_collector_postgres" {
  name       = "otel-collector-postgres"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = "monitoring"
  version    = "0.79.0"
  
  create_namespace = true
  depends_on       = [helm_release.opentelemetry_operator]
  
  values = [
    yamlencode({
      mode = "deployment"
      
      config = {
        receivers = {
          postgresql = {
            endpoint  = "${var.postgres_host}:5432"
            transport = "tcp"
            username  = var.postgres_user
            password  = var.postgres_password
            databases = ["mydb"]
            collection_interval = "10s"
            metrics = {
              "postgresql.blocks_read" = { enabled = true }
              "postgresql.commits" = { enabled = true }
              "postgresql.db.size" = { enabled = true }
            }
          }
        }
        
        processors = {
          batch = {
            timeout = "10s"
            send_batch_size = 1024
          }
          
          resource = {
            attributes = [
              {
                key = "service.name"
                value = "postgres-monitoring"
                action = "upsert"
              }
            ]
          }
        }
        
        exporters = {
          prometheus = {
            endpoint = "0.0.0.0:8889"
          }
          
          otlp = {
            endpoint = "tempo.monitoring.svc.cluster.local:4317"
            tls = {
              insecure = true
            }
          }
          
          logging = {
            loglevel = "info"
          }
        }
        
        service = {
          pipelines = {
            metrics = {
              receivers  = ["postgresql"]
              processors = ["batch", "resource"]
              exporters  = ["prometheus", "logging"]
            }
          }
        }
      }
      
      serviceMonitor = {
        enabled = true
      }
    })
  ]
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "56.0.0"
  
  create_namespace = true
  
  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          
          additionalScrapeConfigs = [
            {
              job_name = "otel-collector"
              static_configs = [
                {
                  targets = ["otel-collector-postgres-opentelemetry-collector.monitoring.svc.cluster.local:8889"]
                }
              ]
            }
          ]
        }
      }
      
      grafana = {
        enabled = true
        adminPassword = var.grafana_password
      }
    })
  ]
} 

