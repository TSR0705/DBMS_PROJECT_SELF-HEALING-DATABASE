"""
Admin Reviews API router for DBMS self-healing pipeline.
Provides read-only access to admin review data.
"""

from fastapi import APIRouter, HTTPException, Path, Query
from typing import List, Optional
import logging

from ..database.connection import db
from ..models.schemas import AdminReview

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/admin-reviews", tags=["Admin Reviews"])

@router.get("/", response_model=List[AdminReview])
async def get_all_admin_reviews(
    limit: Optional[int] = Query(100, description="Maximum number of records to return")
):
    """
    Retrieve all admin review records.
    
    Returns reviews ordered by review time (most recent first).
    """
    query = """
    SELECT 
        review_id,
        decision_id,
        issue_id,
        review_status,
        issue_type,
        action_type,
        admin_action,
        admin_comment,
        override_flag,
        reviewed_at
    FROM admin_reviews 
    ORDER BY review_id DESC
    LIMIT %s
    """
    
    try:
        results = db.execute_read_query(query, (limit,))
        logger.info(f"Retrieved {len(results)} admin review records")
        
        # Convert results to match Pydantic model
        reviews = []
        for row in results:
            review = AdminReview(
                review_id=str(row['review_id']),
                decision_id=str(row['decision_id']),
                issue_id=str(row['issue_id']),
                review_status=row['review_status'],
                issue_type=row['issue_type'],
                action_type=row['action_type'],
                admin_action=row['admin_action'],
                admin_comment=row['admin_comment'],
                override_flag=bool(row['override_flag']),
                reviewed_at=row['reviewed_at']
            )
            reviews.append(review)
        
        return reviews
        
    except Exception as e:
        logger.error(f"Error retrieving admin review records: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve admin review records from database"
        )

@router.get("/{review_id}", response_model=AdminReview)
async def get_admin_review_by_id(
    review_id: str = Path(..., description="Unique identifier of the review")
):
    """
    Retrieve specific admin review by ID.
    """
    query = """
    SELECT 
        review_id,
        decision_id,
        issue_id,
        review_status,
        issue_type,
        action_type,
        admin_action,
        admin_comment,
        override_flag,
        reviewed_at
    FROM admin_reviews 
    WHERE review_id = %s
    """
    
    try:
        results = db.execute_read_query(query, (review_id,))
        
        if not results:
            raise HTTPException(
                status_code=404, 
                detail=f"No admin review found with ID {review_id}"
            )
        
        logger.info(f"Retrieved admin review {review_id}")
        return AdminReview(
            review_id=str(results[0]['review_id']),
            decision_id=str(results[0]['decision_id']),
            issue_id=str(results[0]['issue_id']),
            review_status=results[0]['review_status'],
            issue_type=results[0]['issue_type'],
            action_type=results[0]['action_type'],
            admin_action=results[0]['admin_action'],
            admin_comment=results[0]['admin_comment'],
            override_flag=bool(results[0]['override_flag']),
            reviewed_at=results[0]['reviewed_at']
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving admin review {review_id}: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve admin review from database"
        )

@router.get("/decision/{decision_id}", response_model=List[AdminReview])
async def get_reviews_by_decision(
    decision_id: str = Path(..., description="Decision identifier")
):
    """
    Retrieve all admin reviews for a specific decision.
    """
    query = """
    SELECT 
        review_id,
        decision_id,
        issue_id,
        review_status,
        issue_type,
        action_type,
        admin_action,
        admin_comment,
        override_flag,
        reviewed_at
    FROM admin_reviews 
    WHERE decision_id = %s
    ORDER BY review_id DESC
    """
    
    try:
        results = db.execute_read_query(query, (decision_id,))
        logger.info(f"Retrieved {len(results)} admin reviews for decision {decision_id}")
        
        reviews = []
        for row in results:
            review = AdminReview(
                review_id=str(row['review_id']),
                decision_id=str(row['decision_id']),
                issue_id=str(row['issue_id']),
                review_status=row['review_status'],
                issue_type=row['issue_type'],
                action_type=row['action_type'],
                admin_action=row['admin_action'],
                admin_comment=row['admin_comment'],
                override_flag=bool(row['override_flag']),
                reviewed_at=row['reviewed_at']
            )
            reviews.append(review)
        
        return reviews
        
    except Exception as e:
        logger.error(f"Error retrieving admin reviews for decision {decision_id}: {e}")
        raise HTTPException(
            status_code=500, 
            detail="Failed to retrieve admin review records from database"
        )