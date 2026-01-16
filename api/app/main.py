import logging
import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from database import engine, SessionLocal
from models import Base
from routes import router as todo_router
from contextlib import asynccontextmanager

# OpenTelemetry imports
from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Initialize OpenTelemetry
def init_otel():
    """Initialize OpenTelemetry with OTLP exporters"""
    
    # Create resource for the application
    resource = Resource.create({
        "service.name": "todo-api",
        "service.version": os.environ.get("APP_VERSION", "1.0.0"),
        "deployment.environment": os.environ.get("ENV", "dev"),
    })
    
    # Get OTLP endpoint from environment (set by Kubernetes ADOT instrumentation)
    otlp_endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4317")
    
    try:
        # Configure Trace Provider
        trace_exporter = OTLPSpanExporter(endpoint=otlp_endpoint)
        trace_provider = TracerProvider(resource=resource)
        trace_provider.add_span_processor(BatchSpanProcessor(trace_exporter))
        trace.set_tracer_provider(trace_provider)
        logger.info("Trace provider initialized")
        
        # Configure Metrics Provider
        metric_exporter = OTLPMetricExporter(endpoint=otlp_endpoint)
        metric_reader = PeriodicExportingMetricReader(metric_exporter)
        metrics_provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
        metrics.set_meter_provider(metrics_provider)
        logger.info("Metrics provider initialized")
        
        # Auto-instrument libraries
        SQLAlchemyInstrumentor().instrument(engine=engine)
        RequestsInstrumentor().instrument()
        logger.info("Libraries instrumented")
        
        logger.info(f"OpenTelemetry initialized with OTLP exporter at {otlp_endpoint}")
    except Exception as e:
        logger.warning(f"Failed to initialize OpenTelemetry: {e}. Continuing without instrumentation.")

# Initialize OTEL before creating FastAPI app
init_otel()

# Get tracer for manual spans
tracer = trace.get_tracer(__name__)
meter = metrics.get_meter(__name__)

# Create counters and histograms for manual metrics
task_created_counter = meter.create_counter(
    name="task.created",
    description="Number of tasks created",
    unit="1"
)
task_completed_counter = meter.create_counter(
    name="task.completed",
    description="Number of tasks completed",
    unit="1"
)
api_request_duration = meter.create_histogram(
    name="api.request.duration",
    description="API request duration",
    unit="ms"
)

app = FastAPI()

# Instrument FastAPI app for automatic span creation
FastAPIInstrumentor.instrument_app(app)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom middleware for additional request context
@app.middleware("http")
async def add_trace_context_middleware(request: Request, call_next):
    """Add trace context to requests"""
    with tracer.start_as_current_span("http.request") as span:
        span.set_attribute("http.method", request.method)
        span.set_attribute("http.url", str(request.url))
        span.set_attribute("http.target", request.url.path)
        
        response = await call_next(request)
        
        span.set_attribute("http.status_code", response.status_code)
        return response

try:
    logger.info("Creating database tables if they do not exist")
    Base.metadata.create_all(bind=engine, checkfirst=True)
    logger.info("Database tables ensured/created")
except Exception as e:
    logger.warning(f"DB table creation warning (may already exist): {e}")

# Include the todo routes
app.include_router(todo_router)


@app.on_event("startup")
def on_startup():
    logger.info("Application startup", extra={"env": os.environ.get("ENV", "dev")})


@app.on_event("shutdown")
def on_shutdown():
    logger.info("Application shutdown")


@app.get("/")
def read_root():
    logger.info("Root endpoint called")
    return {"message": "Welcome to the Todo List API!"}


@app.get("/health")
def health_check():
    """Liveness probe - vérifie que l'app tourne"""
    logger.debug("Liveness probe invoked")
    return {"status": "healthy"}


@app.get("/ready")
def readiness_check():
    """Readiness probe - vérifie que l'app est prête à recevoir du trafic"""
    logger.debug("Readiness probe invoked")
    return {"status": "healthy"}
