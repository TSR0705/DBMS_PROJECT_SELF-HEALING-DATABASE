"""
Decision Log API router for DBMS self-healing pipeline.
Provides read-only access to decision log data.
"""

from fastapi import APIRouter, HTTPException, Path, Query
from typing import List, Optional
import logging

from ..database.connection import db
from ..models.schemas import DecisionLog

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/decisions", tags=["Decision Log"])

@router.get("/", response_model=List[DecisionLog])
async def get_all_decisions(
    limit: Optional[int] = Query(100, description="Maximum number of records to return"),
    decision_type: Optional[str] = Query(None, description="Filter by decision type")
):
    """
    Retrieve all decision log records.
    
    Returns decisions ordered by decision time (most recent first).
    """
    base_query = """
    SELECT 
        decision_id,
        issue_id,
        decision_type,
        decision_reason,
        confidence_at_decision,
        decided_at
    FROM decision_log 
    """
    
    params = []
    if decision_type:
        base_query += "WHERE decision_type = %s "
        params.append(decision_type)
    
    base_query += "ORDER BY decided_at DESC LIMIT %s"
    params.append(limit)
    
    try:
        results = db.execute_read_query(base_query, tuple(params))
        logger.info(f"Retrieved {len(results)} decision log records")
        
        # Convert results to match Pydantic model
        decisions = []
        for row in results:
            decision = DecisionLog(
                decision_id=str(row['decision_id']),
                issue_id=str(row['issue_id']),
                decision_type=row['decision_type'],
                decision_reason=row['decision_reason'],
                confidence_at_decision=row['confidence_at_decision'],
                decided_at=row['decided_at']
            )
            decisions.append(decision)
        
        return decisions
        
    except Exception as e:
        logger.error(f"Error retrieving decision log records: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve decision log records from database"
        )

@router.get("/{decision_id}", response_model=DecisionLog)
async def get_decision_by_id(
    decision_id: str = Path(..., description="Unique identifier of the decision")
):
    """
    Retrieve specific decision by ID.
    """
    query = """
    SELECT 
        decision_id,
        issue_id,
        decision_type,
        decision_reason,
        confidence_at_decision,
        decided_at
    FROM decision_log 
    WHERE decision_id = %s
    """
    
    try:
        results = db.execute_read_query(query, (decision_id,))
        
        if not results:
            raise HTTPException(
                status_code=404, 
                detail=f"No decision found with ID {decision_id}"
            )
        
        logger.info(f"Retrieved decision {decision_id}")
        return DecisionLog(**results[0])
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving decision {decision_id}: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve decision from database"
        )

@router.get("/issue/{issue_id}", response_model=List[DecisionLog])
async def get_decisions_by_issue(
    issue_id: str = Path(..., description="Issue identifier")
):
    """
    Retrieve all decisions for a specific issue.
    """
    query = """
    SELECT 
        decision_id,
        issue_id,
        decision_type,
        decision_reason,
        confidence_at_decision,
        decided_at
    FROM decision_log 
    WHERE issue_id = %s
    ORDER BY decided_at DESC
    """
    
    try:
        results = db.execute_read_query(query, (issue_id,))
        logger.info(f"Retrieved {len(results)} decisions for issue {issue_id}")
        
        decisions = []
        for row in results:
            decision = DecisionLog(
                decision_id=str(row['decision_id']),
                issue_id=str(row['issue_id']),
                decision_type=row['decision_type'],
                decision_reason=row['decision_reason'],
                confidence_at_decision=row['confidence_at_decision'],
                decided_at=row['decided_at']
            )
            decisions.append(decision)
        
        return decisions
        
    except Exception as e:
        logger.error(f"Error retrieving decisions for issue {issue_id}: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve decision records from database"
        )