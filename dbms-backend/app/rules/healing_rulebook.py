"""
DBMS Self-Healing Rulebook
Official rule definitions for deterministic, auditable decision making.

This module contains the complete rule set for DBMS issue resolution.
All rules are hardcoded, explicit, and academically defensible.
"""

from enum import Enum
from typing import Dict, NamedTuple, Optional
from decimal import Decimal

class IssueType(Enum):
    """
    Supported DBMS issue types.
    Each type maps to specific detection sources and resolution strategies.
    """
    DEADLOCK = "DEADLOCK"
    SLOW_QUERY = "SLOW_QUERY"
    CONNECTION_OVERLOAD = "CONNECTION_OVERLOAD"
    TRANSACTION_FAILURE = "TRANSACTION_FAILURE"
    LOCK_WAIT = "LOCK_WAIT"

class DecisionType(Enum):
    """
    Decision types for issue resolution.
    Determines whether system can auto-heal or requires human intervention.
    """
    AUTO_HEAL = "AUTO_HEAL"
    ADMIN_REVIEW = "ADMIN_REVIEW"
    ESCALATED = "ESCALATED"

class ActionType(Enum):
    """
    Healing action types.
    All actions are SIMULATED for safety - no real DB mutations.
    """
    ROLLBACK_TRANSACTION = "ROLLBACK_TRANSACTION"
    RETRY_OPERATION = "RETRY_OPERATION"
    NONE = "NONE"
    KILL_CONNECTION = "KILL_CONNECTION"  # SIMULATED ONLY
    OPTIMIZE_QUERY = "OPTIMIZE_QUERY"    # RECOMMENDATION ONLY

class ExecutionMode(Enum):
    """
    Execution modes for healing actions.
    """
    AUTOMATIC = "AUTOMATIC"
    MANUAL = "MANUAL"
    SIMULATED = "SIMULATED"

class ExecutionStatus(Enum):
    """
    Status of healing action execution.
    """
    SUCCESS = "SUCCESS"
    FAILED = "FAILED"
    PENDING = "PENDING"
    SIMULATED = "SIMULATED"

class HealingRule(NamedTuple):
    """
    Represents a single healing rule.
    Immutable structure for deterministic rule application.
    """
    issue_type: IssueType
    decision_type: DecisionType
    action_type: ActionType
    execution_mode: ExecutionMode
    reason: str
    confidence: Decimal
    conditions: Optional[Dict] = None

class HealingRulebook:
    """
    Official DBMS Self-Healing Rulebook.
    
    Contains all approved rules for automatic and manual issue resolution.
    Rules are based on DBMS best practices and academic safety principles.
    """
    
    # Retry thresholds for transient issues
    MAX_RETRY_COUNT = 3
    LOCK_WAIT_TIMEOUT_THRESHOLD = 30  # seconds
    CONNECTION_THRESHOLD = 100  # max connections before review
    
    # Official rule set - IMMUTABLE
    RULES = [
        # DEADLOCK RULES
        HealingRule(
            issue_type=IssueType.DEADLOCK,
            decision_type=DecisionType.AUTO_HEAL,
            action_type=ActionType.ROLLBACK_TRANSACTION,
            execution_mode=ExecutionMode.SIMULATED,
            reason="InnoDB already chooses deadlock victim; rollback is safe and deterministic",
            confidence=Decimal('0.95'),
            conditions=None
        ),
        
        # SLOW QUERY RULES
        HealingRule(
            issue_type=IssueType.SLOW_QUERY,
            decision_type=DecisionType.ADMIN_REVIEW,
            action_type=ActionType.NONE,
            execution_mode=ExecutionMode.MANUAL,
            reason="Slow queries require query analysis, index optimization, or schema redesign",
            confidence=Decimal('1.00'),
            conditions=None
        ),
        
        # CONNECTION OVERLOAD RULES
        HealingRule(
            issue_type=IssueType.CONNECTION_OVERLOAD,
            decision_type=DecisionType.ADMIN_REVIEW,
            action_type=ActionType.NONE,
            execution_mode=ExecutionMode.MANUAL,
            reason="Connection limits require capacity planning; killing connections may break applications",
            confidence=Decimal('1.00'),
            conditions=None
        ),
        
        # TRANSACTION FAILURE RULES (with retry logic)
        HealingRule(
            issue_type=IssueType.TRANSACTION_FAILURE,
            decision_type=DecisionType.AUTO_HEAL,
            action_type=ActionType.RETRY_OPERATION,
            execution_mode=ExecutionMode.SIMULATED,
            reason="Transient transaction failures can be safely retried with exponential backoff",
            confidence=Decimal('0.80'),
            conditions={'max_retries': MAX_RETRY_COUNT}
        ),
        
        # LOCK WAIT RULES (conditional)
        HealingRule(
            issue_type=IssueType.LOCK_WAIT,
            decision_type=DecisionType.AUTO_HEAL,
            action_type=ActionType.RETRY_OPERATION,
            execution_mode=ExecutionMode.SIMULATED,
            reason="Short lock waits can be retried; long waits indicate design issues",
            confidence=Decimal('0.70'),
            conditions={'timeout_threshold': LOCK_WAIT_TIMEOUT_THRESHOLD}
        ),
    ]
    
    @classmethod
    def get_rule_for_issue(cls, issue_type: str, context: Optional[Dict] = None) -> Optional[HealingRule]:
        """
        Get the applicable healing rule for an issue type.
        
        Args:
            issue_type: String representation of issue type
            context: Additional context for conditional rules (retry counts, timeouts, etc.)
            
        Returns:
            HealingRule if found, None otherwise
            
        Raises:
            ValueError: If issue_type is not supported
        """
        try:
            issue_enum = IssueType(issue_type.upper())
        except ValueError:
            # Unknown issue type - escalate to admin
            return HealingRule(
                issue_type=issue_type,
                decision_type=DecisionType.ADMIN_REVIEW,
                action_type=ActionType.NONE,
                execution_mode=ExecutionMode.MANUAL,
                reason=f"Unknown issue type '{issue_type}' requires manual analysis",
                confidence=Decimal('1.00'),
                conditions=None
            )
        
        # Find matching rule
        for rule in cls.RULES:
            if rule.issue_type == issue_enum:
                # Check conditions for conditional rules
                if rule.conditions and context:
                    if not cls._check_conditions(rule, context):
                        # Conditions not met - escalate to admin
                        return HealingRule(
                            issue_type=issue_enum,
                            decision_type=DecisionType.ADMIN_REVIEW,
                            action_type=ActionType.NONE,
                            execution_mode=ExecutionMode.MANUAL,
                            reason=f"Conditions not met for auto-healing {issue_type}",
                            confidence=Decimal('1.00'),
                            conditions=None
                        )
                
                return rule
        
        # No rule found - should not happen with complete rulebook
        return HealingRule(
            issue_type=issue_enum,
            decision_type=DecisionType.ADMIN_REVIEW,
            action_type=ActionType.NONE,
            execution_mode=ExecutionMode.MANUAL,
            reason=f"No rule defined for issue type '{issue_type}'",
            confidence=Decimal('1.00'),
            conditions=None
        )
    
    @classmethod
    def _check_conditions(cls, rule: HealingRule, context: Dict) -> bool:
        """
        Check if conditions are met for conditional rules.
        
        Args:
            rule: The healing rule to check
            context: Context data (retry counts, timeouts, etc.)
            
        Returns:
            True if conditions are met, False otherwise
        """
        if not rule.conditions:
            return True
        
        # Check retry count conditions
        if 'max_retries' in rule.conditions:
            retry_count = context.get('retry_count', 0)
            if retry_count >= rule.conditions['max_retries']:
                return False
        
        # Check timeout conditions
        if 'timeout_threshold' in rule.conditions:
            timeout = context.get('timeout_seconds', 0)
            if timeout > rule.conditions['timeout_threshold']:
                return False
        
        return True
    
    @classmethod
    def get_all_supported_issue_types(cls) -> list[str]:
        """Get list of all supported issue types."""
        return [issue_type.value for issue_type in IssueType]
    
    @classmethod
    def get_rule_summary(cls) -> Dict:
        """
        Get summary of all rules for documentation and verification.
        
        Returns:
            Dictionary containing rule summary
        """
        summary = {
            'total_rules': len(cls.RULES),
            'auto_heal_rules': len([r for r in cls.RULES if r.decision_type == DecisionType.AUTO_HEAL]),
            'admin_review_rules': len([r for r in cls.RULES if r.decision_type == DecisionType.ADMIN_REVIEW]),
            'supported_issue_types': cls.get_all_supported_issue_types(),
            'rules_by_type': {}
        }
        
        for rule in cls.RULES:
            issue_type = rule.issue_type.value
            summary['rules_by_type'][issue_type] = {
                'decision_type': rule.decision_type.value,
                'action_type': rule.action_type.value,
                'execution_mode': rule.execution_mode.value,
                'reason': rule.reason,
                'confidence': float(rule.confidence),
                'has_conditions': rule.conditions is not None
            }
        
        return summary

# Safety validation - ensure all issue types have rules
def validate_rulebook():
    """
    Validate that the rulebook is complete and consistent.
    
    Raises:
        AssertionError: If rulebook validation fails
    """
    issue_types = set(IssueType)
    rule_types = set(rule.issue_type for rule in HealingRulebook.RULES)
    
    # Ensure all issue types have rules
    missing_rules = issue_types - rule_types
    assert not missing_rules, f"Missing rules for issue types: {missing_rules}"
    
    # Ensure all rules have valid confidence scores
    for rule in HealingRulebook.RULES:
        assert 0 <= rule.confidence <= 1, f"Invalid confidence for {rule.issue_type}: {rule.confidence}"
    
    # Ensure AUTO_HEAL rules are safe (simulated only)
    for rule in HealingRulebook.RULES:
        if rule.decision_type == DecisionType.AUTO_HEAL:
            assert rule.execution_mode == ExecutionMode.SIMULATED, \
                f"AUTO_HEAL rule for {rule.issue_type} must be SIMULATED, got {rule.execution_mode}"

# Validate rulebook on import
validate_rulebook()