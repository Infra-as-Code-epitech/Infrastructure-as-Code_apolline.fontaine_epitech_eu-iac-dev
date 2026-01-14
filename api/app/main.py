import logging
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
from models import Base
from routes import router as todo_router

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create the database tables
logger.info("Creating database tables if they do not exist")
Base.metadata.create_all(bind=engine)
logger.info("Database tables ensured/created")

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
    return {"status": "ready"}
