"""
Health Check API router for DBMS self-healing pipeline.
Provides system health and database connectivity status.
"""

from fastapi import APIRouter, HTTPException
from datetime import datetime
import logging

from ..database.connection import db
from ..models.schemas import HealthCheck

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/health", tags=["Health"])

@router.get("/", response_model=HealthCheck)
async def get_health_status():
    """
    Basic health check endpoint for API monitoring.
    
    Returns API status and database connectivity information.
    """
    try:
        # Test database connection
        test_query = "SELECT 1 as test"
        db.execute_read_query(test_query)
        database_connected = True
        
    except Exception as e:
        logger.warning(f"Database health check failed: {e}")
        database_connected = False
    
    return HealthCheck(
        status="healthy" if database_connected else "degraded",
        database_connected=database_connected,
        timestamp=datetime.utcnow()
    )

@router.get("/database")
async def get_database_health():
    """
    Detailed database connectivity and performance check.
    
    Returns database connection status and basic performance metrics.
    """
    try:
        # Test database connection with timing
        start_time = datetime.utcnow()
        test_query = "SELECT 1 as test, NOW() as db_time"
        result = db.execute_read_query(test_query)
        end_time = datetime.utcnow()
        
        response_time_ms = (end_time - start_time).total_seconds() * 1000
        
        return {
            "database_status": "connected",
            "response_time_ms": round(response_time_ms, 2),
            "database_time": result[0]["db_time"] if result else None,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        raise HTTPException(
            status_code=503,
            detail={
                "database_status": "disconnected",
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
        )