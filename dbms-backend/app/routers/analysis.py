"""
AI Analysis API router for DBMS self-healing pipeline.
Provides read-only access to AI analysis data.
"""

from fastapi import APIRouter, HTTPException, Path, Query
from typing import List, Optional
import logging

from ..database.connection import db
from ..models.schemas import AIAnalysis

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/analysis", tags=["AI Analysis"])

@router.get("/", response_model=List[AIAnalysis])
async def get_all_analysis(
    limit: Optional[int] = Query(100, description="Maximum number of records to return")
):
    """
    Retrieve all AI analysis records.
    
    Returns analysis results ordered by analysis time (most recent first).
    """
    query = """
    SELECT 
        analysis_id,
        issue_id,
        predicted_issue_class,
        severity_level,
        risk_type,
        confidence_score,
        model_version,
        analyzed_at
    FROM ai_analysis 
    ORDER BY analyzed_at DESC
    LIMIT %s
    """
    
    try:
        results = db.execute_read_query(query, (limit,))
        logger.info(f"Retrieved {len(results)} AI analysis records")
        
        # Convert results to match Pydantic model
        analyses = []
        for row in results:
            analysis = AIAnalysis(
                analysis_id=str(row['analysis_id']),
                issue_id=str(row['issue_id']),
                predicted_issue_class=row['predicted_issue_class'],
                severity_level=row['severity_level'],
                risk_type=row['risk_type'],
                confidence_score=row['confidence_score'],
                model_version=row['model_version'],
                analyzed_at=row['analyzed_at']
            )
            analyses.append(analysis)
        
        return analyses
        
    except Exception as e:
        logger.error(f"Error retrieving AI analysis records: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve AI analysis records from database"
        )

@router.get("/{analysis_id}", response_model=AIAnalysis)
async def get_analysis_by_id(
    analysis_id: str = Path(..., description="Unique identifier of the analysis")
):
    """
    Retrieve specific AI analysis by ID.
    """
    query = """
    SELECT 
        analysis_id,
        issue_id,
        predicted_issue_class,
        severity_level,
        risk_type,
        confidence_score,
        model_version,
        analyzed_at
    FROM ai_analysis 
    WHERE analysis_id = %s
    """
    
    try:
        results = db.execute_read_query(query, (analysis_id,))
        
        if not results:
            raise HTTPException(
                status_code=404, 
                detail=f"No analysis found with ID {analysis_id}"
            )
        
        logger.info(f"Retrieved analysis {analysis_id}")
        return AIAnalysis(**results[0])
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving analysis {analysis_id}: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve analysis from database"
        )

@router.get("/issue/{issue_id}", response_model=List[AIAnalysis])
async def get_analysis_by_issue(
    issue_id: str = Path(..., description="Issue identifier")
):
    """
    Retrieve all AI analysis records for a specific issue.
    """
    query = """
    SELECT 
        analysis_id,
        issue_id,
        predicted_issue_class,
        severity_level,
        risk_type,
        confidence_score,
        model_version,
        analyzed_at
    FROM ai_analysis 
    WHERE issue_id = %s
    ORDER BY analyzed_at DESC
    """
    
    try:
        results = db.execute_read_query(query, (issue_id,))
        logger.info(f"Retrieved {len(results)} analysis records for issue {issue_id}")
        
        analyses = []
        for row in results:
            analysis = AIAnalysis(
                analysis_id=str(row['analysis_id']),
                issue_id=str(row['issue_id']),
                predicted_issue_class=row['predicted_issue_class'],
                severity_level=row['severity_level'],
                risk_type=row['risk_type'],
                confidence_score=row['confidence_score'],
                model_version=row['model_version'],
                analyzed_at=row['analyzed_at']
            )
            analyses.append(analysis)
        
        return analyses
        
    except Exception as e:
        logger.error(f"Error retrieving analysis for issue {issue_id}: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve analysis records from database"
        )