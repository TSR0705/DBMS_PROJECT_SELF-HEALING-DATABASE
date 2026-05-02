"""
Statistics API router for DBMS self-healing pipeline.
Provides total counts and aggregate statistics for dashboard metrics.
"""

from fastapi import APIRouter, HTTPException
import logging

from ..database.connection import db

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/stats", tags=["Statistics"])

@router.get("/counts")
async def get_all_counts():
    """
    Retrieve total counts for all major entities in the database.
    
    Returns:
        - total_issues: Total number of detected issues
        - total_analysis: Total number of AI analyses performed
        - total_decisions: Total number of decisions made
        - total_actions: Total number of healing actions
        - total_reviews: Total number of admin reviews
        - total_learning: Total number of learning records
        - critical_issues: Number of high severity issues
        - pending_reviews: Number of pending admin reviews
        - auto_healed: Number of successfully auto-healed issues
    """
    try:
        # Execute all count queries
        counts_query = """
        SELECT 
            (SELECT COUNT(*) FROM detected_issues) as total_issues,
            (SELECT COUNT(*) FROM ai_analysis) as total_analysis,
            (SELECT COUNT(*) FROM decision_log) as total_decisions,
            (SELECT COUNT(*) FROM healing_actions) as total_actions,
            (SELECT COUNT(*) FROM admin_reviews) as total_reviews,
            (SELECT COUNT(*) FROM learning_history) as total_learning,
            (SELECT COUNT(*) FROM ai_analysis WHERE severity_level = 'HIGH') as critical_issues,
            (SELECT COUNT(*) FROM admin_reviews WHERE review_status = 'PENDING') as pending_reviews,
            (SELECT COUNT(*) FROM healing_actions WHERE execution_status = 'SUCCESS') as auto_healed
        """
        
        result = db.execute_read_query(counts_query)
        
        if not result:
            raise HTTPException(
                status_code=500,
                detail="Failed to retrieve counts from database"
            )
        
        counts = result[0]
        logger.info(f"Retrieved database counts: {counts}")
        
        return {
            "total_issues": counts['total_issues'],
            "total_analysis": counts['total_analysis'],
            "total_decisions": counts['total_decisions'],
            "total_actions": counts['total_actions'],
            "total_reviews": counts['total_reviews'],
            "total_learning": counts['total_learning'],
            "critical_issues": counts['critical_issues'],
            "pending_reviews": counts['pending_reviews'],
            "auto_healed": counts['auto_healed']
        }
        
    except Exception as e:
        logger.error(f"Error retrieving database counts: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve statistics: {str(e)}"
        )

@router.get("/summary")
async def get_dashboard_summary():
    """
    Retrieve comprehensive dashboard summary statistics.
    
    Includes counts, averages, and key performance indicators.
    """
    try:
        summary_query = """
        SELECT 
            -- Counts
            (SELECT COUNT(*) FROM detected_issues) as total_issues,
            (SELECT COUNT(*) FROM ai_analysis WHERE severity_level = 'HIGH') as critical_issues,
            (SELECT COUNT(*) FROM healing_actions WHERE execution_status = 'SUCCESS') as auto_healed,
            (SELECT COUNT(*) FROM admin_reviews WHERE review_status = 'PENDING') as pending_reviews,
            
            -- Averages
            (SELECT AVG(confidence_score) FROM ai_analysis) as avg_confidence,
            (SELECT AVG(severity_ratio) FROM ai_analysis WHERE severity_ratio IS NOT NULL) as avg_severity_ratio,
            
            -- Detection sources
            (SELECT COUNT(DISTINCT detection_source) FROM detected_issues) as detection_sources,
            
            -- Latest timestamps
            (SELECT MAX(detected_at) FROM detected_issues) as last_detection,
            (SELECT MAX(analyzed_at) FROM ai_analysis) as last_analysis,
            (SELECT MAX(decided_at) FROM decision_log) as last_decision,
            
            -- Model info
            (SELECT model_version FROM ai_analysis ORDER BY analyzed_at DESC LIMIT 1) as current_model_version
        """
        
        result = db.execute_read_query(summary_query)
        
        if not result:
            raise HTTPException(
                status_code=500,
                detail="Failed to retrieve summary from database"
            )
        
        summary = result[0]
        logger.info(f"Retrieved dashboard summary")
        
        return {
            "counts": {
                "total_issues": summary['total_issues'],
                "critical_issues": summary['critical_issues'],
                "auto_healed": summary['auto_healed'],
                "pending_reviews": summary['pending_reviews']
            },
            "averages": {
                "confidence": float(summary['avg_confidence']) if summary['avg_confidence'] else 0.0,
                "severity_ratio": float(summary['avg_severity_ratio']) if summary['avg_severity_ratio'] else 0.0
            },
            "metadata": {
                "detection_sources": summary['detection_sources'],
                "current_model_version": summary['current_model_version'],
                "last_detection": summary['last_detection'].isoformat() if summary['last_detection'] else None,
                "last_analysis": summary['last_analysis'].isoformat() if summary['last_analysis'] else None,
                "last_decision": summary['last_decision'].isoformat() if summary['last_decision'] else None
            }
        }
        
    except Exception as e:
        logger.error(f"Error retrieving dashboard summary: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve summary: {str(e)}"
        )
