"""
FastAPI application for DBMS self-healing pipeline.
Provides read-only API access to DBMS monitoring and healing data.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
import os
from datetime import datetime

from .routers import issues, actions, health, analysis, decisions, admin_reviews, learning

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI application
app = FastAPI(
    title="DBMS Self-Healing API",
    description="Read-only API for DBMS self-healing pipeline data access",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],  # Next.js dev servers
    allow_credentials=True,
    allow_methods=["GET"],  # Read-only API
    allow_headers=["*"],
)

# Include API routers
app.include_router(health.router)
app.include_router(issues.router)
app.include_router(actions.router)
app.include_router(analysis.router)
app.include_router(decisions.router)
app.include_router(admin_reviews.router)
app.include_router(learning.router)

@app.get("/")
async def root():
    """
    API root endpoint with basic information.
    """
    return {
        "name": "DBMS Self-Healing API",
        "version": "1.0.0",
        "description": "Read-only API for DBMS self-healing pipeline data",
        "timestamp": datetime.utcnow().isoformat(),
        "endpoints": {
            "health": "/health",
            "database_health": "/health/database",
            "issues": "/issues",
            "ai_analysis": "/analysis",
            "decisions": "/decisions",
            "actions": "/actions",
            "admin_reviews": "/admin-reviews",
            "learning_history": "/learning",
            "docs": "/docs"
        }
    }

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """
    Global exception handler for unhandled errors.
    """
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "message": "An unexpected error occurred",
            "timestamp": datetime.utcnow().isoformat()
        }
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )