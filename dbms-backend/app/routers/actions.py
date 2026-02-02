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
    status: Optional[str] = Query(None, description="Filter by execution status")
):
    """
    Retrieve healing actions from the self-healing system.
    
    Returns actions ordered by execution time (most recent first).
    Supports filtering by execution status and pagination.
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
    WHERE executed_at IS NOT NULL
    """
    
    params = []
    if status:
        query += " AND execution_status = %s"
        params.append(status)
    
    query += " ORDER BY executed_at DESC LIMIT %s"
    params.append(limit)
    
    try:
        results = db.execute_read_query(query, tuple(params))
        logger.info(f"Retrieved {len(results)} healing actions")
        
        # Convert results to match Pydantic model
        actions = []
        for row in results:
            action = HealingAction(
                action_id=str(row['action_id']),
                decision_id=str(row['decision_id']),
                action_type=row['action_type'],
                execution_mode=row['execution_mode'],
                executed_by=row['executed_by'],
                execution_status=row['execution_status'],
                executed_at=row['executed_at']
            )
            actions.append(action)
        
        return actions
        
    except Exception as e:
        logger.error(f"Error retrieving healing actions: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve healing actions from database"
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