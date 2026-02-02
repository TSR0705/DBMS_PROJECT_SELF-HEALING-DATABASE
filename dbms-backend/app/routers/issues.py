"""
Issues API router for DBMS self-healing pipeline.
Provides read-only access to detected issues and related analysis data.
"""

from fastapi import APIRouter, HTTPException, Path
from typing import List
import logging

from ..database.connection import db
from ..models.schemas import DetectedIssue, IssueAnalysis, IssueDecision

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/issues", tags=["Issues"])

@router.get("/", response_model=List[DetectedIssue])
async def get_detected_issues():
    """
    Retrieve all detected issues from DBMS monitoring systems.
    
    Returns issues ordered by detection time (most recent first).
    Query joins detection metadata for comprehensive issue view.
    """
    query = """
    SELECT 
        issue_id,
        issue_type,
        detection_source,
        raw_metric_value,
        raw_metric_unit,
        detected_at
    FROM detected_issues 
    WHERE detected_at IS NOT NULL
    ORDER BY detected_at DESC
    LIMIT 100
    """
    
    try:
        results = db.execute_read_query(query)
        logger.info(f"Retrieved {len(results)} detected issues")
        
        # Convert results to match Pydantic model
        issues = []
        for row in results:
            issue = DetectedIssue(
                issue_id=str(row['issue_id']),
                issue_type=row['issue_type'],
                detection_source=row['detection_source'],
                raw_metric_value=float(row['raw_metric_value']) if row['raw_metric_value'] is not None else None,
                raw_metric_unit=row['raw_metric_unit'],
                detected_at=row['detected_at']
            )
            issues.append(issue)
        
        return issues
        
    except Exception as e:
        logger.error(f"Error retrieving detected issues: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve detected issues from database"
        )

@router.get("/{issue_id}/analysis", response_model=IssueAnalysis)
async def get_issue_analysis(
    issue_id: str = Path(..., description="Unique identifier of the issue")
):
    """
    Retrieve AI analysis results for a specific issue.
    
    Returns the most recent analysis if multiple analyses exist.
    Analysis includes AI predictions, severity assessment, and confidence scores.
    """
    query = """
    SELECT 
        issue_id,
        predicted_issue_class,
        severity_level,
        confidence_score,
        analyzed_at
    FROM ai_analysis 
    WHERE issue_id = %s
    ORDER BY analyzed_at DESC
    LIMIT 1
    """
    
    try:
        results = db.execute_read_query(query, (issue_id,))
        
        if not results:
            raise HTTPException(
                status_code=404, 
                detail=f"No analysis found for issue {issue_id}"
            )
        
        logger.info(f"Retrieved analysis for issue {issue_id}")
        return IssueAnalysis(**results[0])
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving analysis for issue {issue_id}: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve issue analysis from database"
        )

@router.get("/{issue_id}/decision", response_model=IssueDecision)
async def get_issue_decision(
    issue_id: str = Path(..., description="Unique identifier of the issue")
):
    """
    Retrieve decision made for a specific issue.
    
    Returns the most recent decision if multiple decisions exist.
    Decision includes resolution strategy, rationale, and decision metadata.
    """
    query = """
    SELECT 
        issue_id,
        decision_type,
        decision_reason,
        decided_at
    FROM decision_log 
    WHERE issue_id = %s
    ORDER BY decided_at DESC
    LIMIT 1
    """
    
    try:
        results = db.execute_read_query(query, (issue_id,))
        
        if not results:
            raise HTTPException(
                status_code=404, 
                detail=f"No decision found for issue {issue_id}"
            )
        
        logger.info(f"Retrieved decision for issue {issue_id}")
        return IssueDecision(**results[0])
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving decision for issue {issue_id}: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve issue decision from database"
        )