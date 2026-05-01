"""
Healing Actions API router for DBMS self-healing pipeline.
Provides read-only access to healing actions and execution status.
"""

from fastapi import APIRouter, HTTPException, Path, Query
from typing import List, Optional
import logging

from ..database.connection import db
from ..models.schemas import HealingAction

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/actions", tags=["Healing Actions"])

@router.get("/", response_model=List[HealingAction])
async def get_healing_actions(
    limit: int = Query(50, ge=1, le=100, description="Maximum number of actions to return"),
    status: Optional[str] = Query(None, description="Filter by system status")
):
    """
    Retrieve a unified view of healing actions and queue states.
    
    Returns a combined view of decisions, their queue status, and execution results.
    Ordered by decision time (most recent first).
    """
    query = """
    SELECT 
        d.decision_id,
        di.issue_type,
        d.decision_type,
        q.status AS queue_status,
        h.action_id,
        h.action_type,
        h.execution_mode,
        h.executed_by,
        h.execution_status,
        h.verification_status,
        q.created_at AS queued_at,
        h.executed_at,
        CASE
            WHEN q.status = 'PENDING' THEN 'QUEUED'
            WHEN q.status = 'PROCESSING' THEN 'RUNNING'
            WHEN d.decision_type = 'ADMIN_REVIEW' AND h.execution_status IS NULL THEN 'QUEUED'
            WHEN h.execution_status = 'SUCCESS' THEN 'COMPLETED'
            WHEN h.execution_status = 'FAILED' THEN 'FAILED'
            WHEN h.execution_status = 'SKIPPED' THEN 'SKIPPED'
            ELSE 'UNKNOWN'
        END AS system_status
    FROM decision_log d
    JOIN detected_issues di ON d.issue_id = di.issue_id
    LEFT JOIN execution_queue q ON d.decision_id = q.decision_id
    LEFT JOIN healing_actions h ON d.decision_id = h.decision_id
    WHERE 1=1
    """
    
    params = []
    if status:
        query += " HAVING system_status = %s"
        params.append(status)
    
    query += " ORDER BY d.decision_id DESC LIMIT %s"
    params.append(limit)
    
    try:
        results = db.execute_read_query(query, tuple(params))
        logger.info(f"Retrieved {len(results)} unified healing actions")
        
        actions = []
        for row in results:
            action = HealingAction(
                action_id=str(row['action_id']) if row['action_id'] else None,
                decision_id=str(row['decision_id']),
                issue_type=row['issue_type'],
                decision_type=row['decision_type'],
                action_type=row['action_type'],
                execution_mode=row['execution_mode'],
                executed_by=row['executed_by'],
                queue_status=row['queue_status'],
                execution_status=row['execution_status'],
                system_status=row['system_status'],
                queued_at=row['queued_at'],
                executed_at=row['executed_at']
            )
            actions.append(action)
        
        return actions
        
    except Exception as e:
        logger.error(f"Error retrieving unified healing actions: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve unified actions from database"
        )

@router.get("/{action_id}", response_model=HealingAction)
async def get_healing_action(
    action_id: str = Path(..., description="Unique identifier of the healing action")
):
    """
    Retrieve details of a specific healing action.
    
    Returns complete action information including execution status and timing.
    """
    query = """
    SELECT 
        action_id,
        decision_id,
        action_type,
        execution_mode,
        executed_by,
        execution_status,
        executed_at
    FROM healing_actions 
    WHERE action_id = %s
    """
    
    try:
        results = db.execute_read_query(query, (action_id,))
        
        if not results:
            raise HTTPException(
                status_code=404, 
                detail=f"No healing action found with ID {action_id}"
            )
        
        logger.info(f"Retrieved healing action {action_id}")
        return HealingAction(
            action_id=str(results[0]['action_id']),
            decision_id=str(results[0]['decision_id']),
            action_type=results[0]['action_type'],
            execution_mode=results[0]['execution_mode'],
            executed_by=results[0]['executed_by'],
            execution_status=results[0]['execution_status'],
            executed_at=results[0]['executed_at']
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving healing action {action_id}: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve healing action from database"
        )