# OpenTelemetry Instrumentation Guide

This document describes the OpenTelemetry (OTel) manual instrumentation added to the Todo API.

## Overview

The application is instrumented with comprehensive OpenTelemetry support to export:

- **Traces**: Request spans, database operations, and custom business logic spans
- **Metrics**: Task creation/completion counters and request duration histograms
- **Logs**: Structured logs with full trace correlation

## Changes Made

### 1. Dependencies Added (`requirements.txt`)

```
opentelemetry-api
opentelemetry-sdk
opentelemetry-instrumentation
opentelemetry-exporter-otlp-proto-grpc
opentelemetry-instrumentation-logging
opentelemetry-instrumentation-requests
opentelemetry-instrumentation-urllib3
```

### 2. OpenTelemetry Initialization (`app/main.py`)

- **TraceProvider**: Configured to export spans to OTLP gRPC endpoint
- **MeterProvider**: Exports metrics every 5 seconds
- **LoggerProvider**: Exports structured logs with trace correlation
- **Auto-Instrumentation**:
  - FastAPI: Automatic HTTP span creation
  - SQLAlchemy: Database operation tracing
  - Logging: Log correlation with traces
  - HTTP libraries: requests and urllib3 instrumentation

### 3. Custom Middleware (`app/main.py`)

A custom middleware adds HTTP context to all requests:

- HTTP method, URL, and target path
- Response status code
- Creates spans for all HTTP requests

### 4. Manual Spans in Route Handlers (`app/routes.py`)

Each endpoint is instrumented with manual spans:

- `list_tasks`: Span with task count attribute
- `create_task`: Span with task title and ID
- `get_task`: Span with task ID and error tracking
- `update_task`: Span with task ID and error tracking
- `toggle_complete`: Span with completion status
- `delete_task`: Span with task ID and error tracking

### 5. Metrics (`app/main.py`)

Custom counters and histograms for business logic:

- `task.created`: Counter for new tasks
- `task.completed`: Counter for completed tasks
- `api.request.duration`: Histogram for request latency

### 6. Environment Configuration (`.env`)

New OTel settings:

```
ENV=dev
APP_VERSION=1.0.0
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_PYTHON_LOG_CORRELATION=true
```

## Integration with Kubernetes ADOT

The app is pre-configured to work with the existing ADOT (AWS OpenTelemetry Collector) setup in Kubernetes:

1. **Local Development**: Uses `http://localhost:4317` as the OTLP endpoint
2. **Kubernetes**: Set `OTEL_EXPORTER_OTLP_ENDPOINT` to `http://adot-collector.observability.svc.cluster.local:4317`

The ADOT collector (configured in `terraform/app/adot.tf`) will:

- Export traces to AWS X-Ray
- Export metrics to Amazon Prometheus
- Export logs to CloudWatch

## Usage

### Starting the App with Observability

**Local Development** (requires OpenTelemetry Collector running on localhost:4317):

```bash
docker-compose up
```

**Kubernetes**: The app will automatically discover the ADOT collector through the instrumentation configuration.

### Viewing Observability Data

1. **Traces**: AWS X-Ray console
2. **Metrics**: Amazon Prometheus/Grafana
3. **Logs**: CloudWatch Logs (/aws/eks/adot-logs)

## Best Practices Implemented

✅ **Structured Logging**: All logs include relevant context and trace correlation  
✅ **Error Tracking**: Error spans are marked with `error=True` attribute  
✅ **Resource Attributes**: Service name, version, and environment configured  
✅ **Batch Processing**: Spans and metrics batched for efficiency  
✅ **Graceful Degradation**: If OTLP endpoint is unavailable, app continues to function  
✅ **Library Instrumentation**: Automatic tracing for FastAPI, SQLAlchemy, HTTP calls

## Manual Span Creation

To add custom spans in your code:

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

# Create a span
with tracer.start_as_current_span("operation_name") as span:
    span.set_attribute("key", "value")
    # Your code here
```

## Metrics Usage

To record custom metrics:

```python
from opentelemetry import metrics

meter = metrics.get_meter(__name__)
counter = meter.create_counter("metric.name", unit="1")
counter.add(1, {"attribute": "value"})
```
