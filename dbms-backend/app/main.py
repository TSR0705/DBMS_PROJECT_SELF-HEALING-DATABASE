"""
FastAPI application for DBMS self-healing pipeline.
Provides read-only API access to DBMS monitoring and healing data.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import os
from dotenv import load_dotenv
from datetime import datetime, date
from typing import Any, List, Dict

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Import database connection
from .database.connection import db

# Global exports for testing
DB_CONFIG = {
    'host': os.getenv('DB_HOST', '127.0.0.1'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'database': os.getenv('DB_NAME', 'dbms_self_healing_test')
}

def serialize_datetime(value: Any) -> Any:
    """Serialize datetime objects to ISO format strings."""
    if isinstance(value, datetime):
        return value.isoformat()
    elif isinstance(value, date):
        return value.isoformat()
    return value

def process_results(results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Process database results, serializing datetime fields."""
    processed = []
    for row in results:
        processed_row = {}
        for key, value in row.items():
            processed_row[key] = serialize_datetime(value)
        processed.append(processed_row)
    return processed

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