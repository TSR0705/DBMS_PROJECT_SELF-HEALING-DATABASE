"""
Pydantic models for DBMS self-healing pipeline API responses.
Defines strict type validation for all API endpoints.
"""

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
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
    confidence_score: Decimal = Field(..., description="AI confidence score (0.0 to 1.0)")
    model_version: str = Field(..., description="Version of AI model used")
    analyzed_at: datetime = Field(..., description="Timestamp when analysis was completed")
    
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
    Maps to healing_actions table structure.
    """
    action_id: str = Field(..., description="Unique identifier for the healing action")
    decision_id: str = Field(..., description="Reference to the related decision")
    action_type: str = Field(..., description="Type of healing action performed")
    execution_mode: str = Field(..., description="Mode of execution (AUTOMATIC/MANUAL)")
    executed_by: str = Field(..., description="Who/what executed the action")
    execution_status: str = Field(..., description="Current status of action execution")
    executed_at: datetime = Field(..., description="Timestamp when action was executed")
    
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
    admin_action: str = Field(..., description="Action taken by admin")
    admin_comment: Optional[str] = Field(None, description="Admin comments")
    override_flag: bool = Field(..., description="Whether admin overrode the decision")
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
    data: Optional[List[BaseModel]] = Field(None, description="Response data payload")
    
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