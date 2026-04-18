"""
FastAPI application for DBMS self-healing pipeline.
Provides read-only API access to DBMS monitoring and healing data.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Import routers
from .routers import (
    health,
    issues,
    analysis,
    decisions,
    actions,
    admin_reviews,
    learning
)

# Create FastAPI application
app = FastAPI(
    title="DBMS Self-Healing API",
    version="1.0.0",
    description="API for DBMS self-healing pipeline data"
)

# CORS configuration
allowed_origins_str = os.getenv('FRONTEND_URL', 'http://localhost:3000,https://dbms-project-self-healing-database.vercel.app')
allowed_origins = [url.strip() for url in allowed_origins_str.split(',')]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "OPTIONS", "POST", "PUT"],
    allow_headers=["Content-Type", "Authorization"],
)

# Include routers
app.include_router(health.router)
app.include_router(issues.router)
app.include_router(analysis.router)
app.include_router(decisions.router)
app.include_router(actions.router)
app.include_router(admin_reviews.router)
app.include_router(learning.router)

@app.get("/")
def root():
    """API root endpoint."""
    from datetime import datetime, timezone
    return {
        "name": "DBMS Self-Healing API",
        "version": "1.0.0",
        "description": "API for DBMS self-healing pipeline data",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "status": "operational"
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("API_PORT", 8002))
    host = os.getenv("API_HOST", "0.0.0.0")
    uvicorn.run("app.main:app", host=host, port=port, reload=True)