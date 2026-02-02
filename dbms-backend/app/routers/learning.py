"""
Learning History API router for DBMS self-healing pipeline.
Provides read-only access to learning history data.
"""

from fastapi import APIRouter, HTTPException, Path, Query
from typing import List, Optional
import logging

from ..database.connection import db
from ..models.schemas import LearningHistory

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/learning", tags=["Learning History"])

@router.get("/", response_model=List[LearningHistory])
async def get_all_learning_history(
    limit: Optional[int] = Query(100, description="Maximum number of records to return"),
    issue_type: Optional[str] = Query(None, description="Filter by issue type"),
    outcome: Optional[str] = Query(None, description="Filter by outcome")
):
    """
    Retrieve all learning history records.
    
    Returns learning records ordered by recorded time (most recent first).
    """
    base_query = """
    SELECT 
        learning_id,
        issue_type,
        action_type,
        outcome,
        confidence_before,
        confidence_after,
        recorded_at
    FROM learning_history 
    """
    
    params = []
    conditions = []
    
    if issue_type:
        conditions.append("issue_type = %s")
        params.append(issue_type)
    
    if outcome:
        conditions.append("outcome = %s")
        params.append(outcome)
    
    if conditions:
        base_query += "WHERE " + " AND ".join(conditions) + " "
    
    base_query += "ORDER BY recorded_at DESC LIMIT %s"
    params.append(limit)
    
    try:
        results = db.execute_read_query(base_query, tuple(params))
        logger.info(f"Retrieved {len(results)} learning history records")
        
        # Convert results to match Pydantic model
        learning_records = []
        for row in results:
            record = LearningHistory(
                learning_id=str(row['learning_id']),
                issue_type=row['issue_type'],
                action_type=row['action_type'],
                outcome=row['outcome'],
                confidence_before=row['confidence_before'],
                confidence_after=row['confidence_after'],
                recorded_at=row['recorded_at']
            )
            learning_records.append(record)
        
        return learning_records
        
    except Exception as e:
        logger.error(f"Error retrieving learning history records: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve learning history records from database"
        )

@router.get("/{learning_id}", response_model=LearningHistory)
async def get_learning_record_by_id(
    learning_id: str = Path(..., description="Unique identifier of the learning record")
):
    """
    Retrieve specific learning record by ID.
    """
    query = """
    SELECT 
        learning_id,
        issue_type,
        action_type,
        outcome,
        confidence_before,
        confidence_after,
        recorded_at
    FROM learning_history 
    WHERE learning_id = %s
    """
    
    try:
        results = db.execute_read_query(query, (learning_id,))
        
        if not results:
            raise HTTPException(
                status_code=404, 
                detail=f"No learning record found with ID {learning_id}"
            )
        
        logger.info(f"Retrieved learning record {learning_id}")
        return LearningHistory(**results[0])
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving learning record {learning_id}: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve learning record from database"
        )

@router.get("/stats/improvement", response_model=dict)
async def get_learning_improvement_stats():
    """
    Get learning improvement statistics.
    """
    query = """
    SELECT 
        issue_type,
        action_type,
        COUNT(*) as total_records,
        AVG(confidence_before) as avg_confidence_before,
        AVG(confidence_after) as avg_confidence_after,
        AVG(confidence_after - confidence_before) as avg_improvement,
        SUM(CASE WHEN outcome = 'RESOLVED' THEN 1 ELSE 0 END) as successful_outcomes
    FROM learning_history 
    GROUP BY issue_type, action_type
    ORDER BY avg_improvement DESC
    """
    
    try:
        results = db.execute_read_query(query)
        logger.info(f"Retrieved learning improvement stats for {len(results)} combinations")
        
        stats = []
        for row in results:
            stat = {
                "issue_type": row['issue_type'],
                "action_type": row['action_type'],
                "total_records": row['total_records'],
                "avg_confidence_before": float(row['avg_confidence_before']) if row['avg_confidence_before'] else 0,
                "avg_confidence_after": float(row['avg_confidence_after']) if row['avg_confidence_after'] else 0,
                "avg_improvement": float(row['avg_improvement']) if row['avg_improvement'] else 0,
                "successful_outcomes": row['successful_outcomes'],
                "success_rate": (row['successful_outcomes'] / row['total_records']) * 100 if row['total_records'] > 0 else 0
            }
            stats.append(stat)
        
        return {
            "learning_stats": stats,
            "total_combinations": len(stats),
            "timestamp": db.execute_read_query("SELECT NOW() as timestamp")[0]['timestamp'].isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error retrieving learning improvement stats: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve learning improvement statistics"
        )