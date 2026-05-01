"""
Pydantic models for DBMS self-healing pipeline API responses.
Defines strict type validation for all API endpoints.
"""

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List, Any
from decimal import Decimal

class DetectedIssue(BaseModel):
    """
    Represents a detected issue from DBMS monitoring systems.
    Maps to detected_issues table structure.
    """
    issue_id: str = Field(..., description="Unique identifier for the detected issue")
    issue_type: str = Field(..., description="Classification of the issue type")
    detection_source: str = Field(..., description="System component that detected the issue")
    raw_metric_value: Optional[Decimal] = Field(None, description="Raw metric value that triggered detection")
    raw_metric_unit: Optional[str] = Field(None, description="Unit of the raw metric value")
    detected_at: datetime = Field(..., description="Timestamp when issue was first detected")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            Decimal: lambda v: float(v) if v is not None else None
        }

class AIAnalysis(BaseModel):
    """
    Represents AI analysis results for a specific issue.
    Maps to ai_analysis table structure.
    """
    analysis_id: str = Field(..., description="Unique identifier for the analysis")
    issue_id: str = Field(..., description="Reference to the analyzed issue")
    predicted_issue_class: str = Field(..., description="AI-predicted classification of the issue")
    severity_level: str = Field(..., description="Assessed severity level (Critical, High, Medium, Low)")
    risk_type: str = Field(..., description="Type of risk identified")
    confidence_score: Optional[float] = Field(None, description="AI confidence score (0.0 to 1.0)")
    model_version: str = Field(..., description="Version of AI model used")
    analyzed_at: datetime = Field(default_factory=datetime.now, description="Timestamp when analysis was completed")
    baseline_metric: Optional[float] = Field(None, description="Baseline metric for comparison — null when DB value is absent")
    severity_ratio: Optional[float] = Field(None, description="Calculated severity ratio — null when DB value is absent")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            Decimal: lambda v: float(v)
        }

class DecisionLog(BaseModel):
    """
    Represents decision made for issue resolution.
    Maps to decision_log table structure.
    """
    decision_id: str = Field(..., description="Unique identifier for the decision")
    issue_id: str = Field(..., description="Reference to the issue being decided upon")
    decision_type: str = Field(..., description="Type of decision made (Auto, Manual, Escalated)")
    decision_reason: str = Field(..., description="Rationale behind the decision")
    confidence_at_decision: Decimal = Field(..., description="Confidence level at decision time")
    decided_at: datetime = Field(..., description="Timestamp when decision was made")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            Decimal: lambda v: float(v)
        }

class HealingAction(BaseModel):
    """
    Represents healing actions taken by the system.
    Unified view combining decision, queue, and execution state.
    """
    action_id: Optional[str] = Field(None, description="Unique identifier for the healing action")
    decision_id: str = Field(..., description="Reference to the related decision")
    issue_type: Optional[str] = Field(None, description="Type of issue being resolved")
    decision_type: Optional[str] = Field(None, description="Type of decision made")
    action_type: Optional[str] = Field(None, description="Type of healing action performed")
    execution_mode: Optional[str] = Field(None, description="Mode of execution (AUTOMATIC/MANUAL)")
    executed_by: Optional[str] = Field(None, description="Who/what executed the action")
    queue_status: Optional[str] = Field(None, description="Status in the execution queue")
    execution_status: Optional[str] = Field(None, description="Current status of action execution")
    system_status: str = Field(..., description="Computed unified system status")
    queued_at: Optional[datetime] = Field(None, description="Timestamp when task was queued")
    executed_at: Optional[datetime] = Field(None, description="Timestamp when action was executed")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class AdminReview(BaseModel):
    """
    Represents admin review records.
    Maps to admin_reviews table structure.
    """
    review_id: str = Field(..., description="Unique identifier for the review")
    decision_id: str = Field(..., description="Reference to the reviewed decision")
    issue_id: str = Field(..., description="Reference to the related issue")
    review_status: str = Field(..., description="Current status of the review (PENDING, APPROVED, REJECTED)")
    issue_type: Optional[str] = Field(None, description="Type of issue being reviewed")
    action_type: Optional[str] = Field(None, description="Type of action proposed")
    admin_action: Optional[str] = Field(None, description="Action taken by admin")
    admin_comment: Optional[str] = Field(None, description="Admin comments")
    override_flag: bool = Field(False, description="Whether admin overrode the decision")
    reviewed_at: datetime = Field(..., description="Timestamp of review")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class LearningHistory(BaseModel):
    """
    Represents learning history records.
    Maps to learning_history table structure.
    """
    learning_id: str = Field(..., description="Unique identifier for the learning record")
    decision_id: str = Field(..., description="Decision ID this learning record relates to")
    issue_type: str = Field(..., description="Type of issue learned from")
    action_type: str = Field(..., description="Type of action taken")
    outcome: str = Field(..., description="Outcome of the action")
    confidence_before: Decimal = Field(..., description="Confidence before action")
    confidence_after: Decimal = Field(..., description="Confidence after action")
    recorded_at: datetime = Field(..., description="Timestamp of learning record")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            Decimal: lambda v: float(v)
        }

# Legacy models for backward compatibility
class IssueAnalysis(BaseModel):
    """
    Legacy model for AI analysis results - use AIAnalysis instead.
    """
    issue_id: str = Field(..., description="Reference to the analyzed issue")
    predicted_issue_class: str = Field(..., description="AI-predicted classification of the issue")
    severity_level: str = Field(..., description="Assessed severity level (Critical, High, Medium, Low)")
    confidence_score: Decimal = Field(..., description="AI confidence score (0.0 to 1.0)")
    analyzed_at: datetime = Field(..., description="Timestamp when analysis was completed")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            Decimal: lambda v: float(v)
        }

class IssueDecision(BaseModel):
    """
    Legacy model for decision log - use DecisionLog instead.
    """
    issue_id: str = Field(..., description="Reference to the issue being decided upon")
    decision_type: str = Field(..., description="Type of decision made (Auto, Manual, Escalated)")
    decision_reason: str = Field(..., description="Rationale behind the decision")
    decided_at: datetime = Field(..., description="Timestamp when decision was made")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class APIResponse(BaseModel):
    """
    Standard API response wrapper for consistent response format.
    """
    success: bool = Field(..., description="Indicates if the request was successful")
    message: str = Field(..., description="Human-readable response message")
    data: Optional[List[Any]] = Field(None, description="Response data payload")
    
class HealthCheck(BaseModel):
    """
    Health check response for API monitoring.
    """
    status: str = Field(..., description="API health status")
    database_connected: bool = Field(..., description="Database connectivity status")
    timestamp: datetime = Field(..., description="Health check timestamp")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }