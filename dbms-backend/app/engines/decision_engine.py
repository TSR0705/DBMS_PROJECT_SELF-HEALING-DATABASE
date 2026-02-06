"""
DBMS Decision Engine
Implements rule-based decision making for detected DBMS issues.

This engine:
1. Reads NEW records from detected_issues table
2. Applies healing rulebook to determine decisions
3. Inserts decisions into decision_log table
4. NEVER modifies detected_issues table
5. NEVER executes database commands directly

All decisions are deterministic, auditable, and based on explicit rules.
"""

import logging
import uuid
from datetime import datetime
from typing import List, Dict, Optional, Any
from decimal import Decimal

from ..database.connection import DatabaseConnection
from ..rules.healing_rulebook import HealingRulebook, HealingRule

logger = logging.getLogger(__name__)

class DecisionEngine:
    """
    Rule-based decision engine for DBMS self-healing.
    
    Processes detected issues and makes deterministic decisions based on
    the official healing rulebook. All decisions are logged and auditable.
    """
    
    def __init__(self):
        self.db = DatabaseConnection()
        self.rulebook = HealingRulebook()
        
    def process_new_issues(self) -> Dict[str, Any]:
        """
        Process all new (unprocessed) issues from detected_issues table.
        
        Returns:
            Dictionary containing processing results and statistics
        """
        logger.info("Starting decision engine processing...")
        
        results = {
            'timestamp': datetime.now(),
            'issues_processed': 0,
            'decisions_made': 0,
            'auto_heal_decisions': 0,
            'admin_review_decisions': 0,
            'errors': [],
            'decisions': []
        }
        
        try:
            # Get unprocessed issues
            unprocessed_issues = self._get_unprocessed_issues()
            results['issues_processed'] = len(unprocessed_issues)
            
            logger.info(f"Found {len(unprocessed_issues)} unprocessed issues")
            
            # Process each issue
            for issue in unprocessed_issues:
                try:
                    decision = self._make_decision_for_issue(issue)
                    if decision:
                        self._record_decision(decision)
                        results['decisions'].append(decision)
                        results['decisions_made'] += 1
                        
                        if decision['decision_type'] == 'AUTO_HEAL':
                            results['auto_heal_decisions'] += 1
                        elif decision['decision_type'] == 'ADMIN_REVIEW':
                            results['admin_review_decisions'] += 1
                            
                        logger.info(f"Decision made for issue {issue['issue_id']}: {decision['decision_type']}")
                    
                except Exception as e:
                    error_msg = f"Error processing issue {issue.get('issue_id', 'unknown')}: {str(e)}"
                    logger.error(error_msg)
                    results['errors'].append(error_msg)
            
            logger.info(f"Decision engine completed: {results['decisions_made']} decisions made")
            
        except Exception as e:
            error_msg = f"Critical error in decision engine: {str(e)}"
            logger.error(error_msg)
            results['errors'].append(error_msg)
        
        return results
    
    def _get_unprocessed_issues(self) -> List[Dict[str, Any]]:
        """
        Get issues that haven't been processed yet (no decision recorded).
        
        Returns:
            List of unprocessed issue records
        """
        query = """
        SELECT 
            di.issue_id,
            di.issue_type,
            di.detection_source,
            di.raw_metric_value,
            di.raw_metric_unit,
            di.detected_at
        FROM detected_issues di
        LEFT JOIN decision_log dl ON di.issue_id = dl.issue_id
        WHERE dl.issue_id IS NULL
        ORDER BY di.detected_at ASC
        """
        
        try:
            # Use read-only connection for safety
            with self.db.get_connection() as conn:
                cursor = conn.cursor(dictionary=True)
                cursor.execute(query)
                results = cursor.fetchall()
                cursor.close()
                return results
                
        except Exception as e:
            logger.error(f"Error fetching unprocessed issues: {e}")
            return []
    
    def _make_decision_for_issue(self, issue: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Make a decision for a specific issue using the healing rulebook.
        
        Args:
            issue: Issue record from detected_issues table
            
        Returns:
            Decision record to be inserted into decision_log, or None if error
        """
        try:
            issue_id = str(issue['issue_id'])
            issue_type = issue['issue_type']
            
            # Build context for conditional rules
            context = self._build_decision_context(issue)
            
            # Get applicable rule from rulebook
            rule = self.rulebook.get_rule_for_issue(issue_type, context)
            
            if not rule:
                logger.warning(f"No rule found for issue type: {issue_type}")
                return None
            
            # Create decision record
            decision = {
                'decision_id': str(uuid.uuid4()),
                'issue_id': issue_id,
                'decision_type': rule.decision_type.value,
                'decision_reason': self._build_decision_reason(rule, issue, context),
                'confidence_at_decision': rule.confidence,
                'decided_at': datetime.now(),
                'rule_applied': {
                    'issue_type': rule.issue_type.value if hasattr(rule.issue_type, 'value') else str(rule.issue_type),
                    'action_type': rule.action_type.value,
                    'execution_mode': rule.execution_mode.value,
                    'conditions_checked': rule.conditions is not None
                }
            }
            
            logger.info(f"Decision made for issue {issue_id}: {rule.decision_type.value} - {rule.reason}")
            
            return decision
            
        except Exception as e:
            logger.error(f"Error making decision for issue {issue.get('issue_id', 'unknown')}: {e}")
            return None
    
    def _build_decision_context(self, issue: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build context information for conditional rule evaluation.
        
        Args:
            issue: Issue record
            
        Returns:
            Context dictionary with relevant information
        """
        context = {
            'issue_id': issue['issue_id'],
            'detection_source': issue['detection_source'],
            'metric_value': float(issue['raw_metric_value']) if issue['raw_metric_value'] else 0,
            'metric_unit': issue['raw_metric_unit'],
            'detected_at': issue['detected_at']
        }
        
        # Add issue-specific context
        if issue['issue_type'] == 'LOCK_WAIT':
            # For lock waits, metric_value should be timeout in seconds
            context['timeout_seconds'] = context['metric_value']
        
        elif issue['issue_type'] == 'TRANSACTION_FAILURE':
            # Check for previous retry attempts (would need additional tracking)
            context['retry_count'] = self._get_retry_count_for_issue(issue['issue_id'])
        
        elif issue['issue_type'] == 'CONNECTION_OVERLOAD':
            # For connection issues, metric_value should be connection count
            context['connection_count'] = int(context['metric_value'])
        
        return context
    
    def _get_retry_count_for_issue(self, issue_id: str) -> int:
        """
        Get the number of retry attempts for a specific issue.
        
        Args:
            issue_id: Issue identifier
            
        Returns:
            Number of previous retry attempts
        """
        query = """
        SELECT COUNT(*) as retry_count
        FROM healing_actions ha
        JOIN decision_log dl ON ha.decision_id = dl.decision_id
        WHERE dl.issue_id = %s AND ha.action_type = 'RETRY_OPERATION'
        """
        
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor(dictionary=True)
                cursor.execute(query, (issue_id,))
                result = cursor.fetchone()
                cursor.close()
                return result['retry_count'] if result else 0
                
        except Exception as e:
            logger.error(f"Error getting retry count for issue {issue_id}: {e}")
            return 0
    
    def _build_decision_reason(self, rule: HealingRule, issue: Dict[str, Any], context: Dict[str, Any]) -> str:
        """
        Build a detailed decision reason for audit trail.
        
        Args:
            rule: Applied healing rule
            issue: Issue record
            context: Decision context
            
        Returns:
            Detailed reason string
        """
        base_reason = rule.reason
        
        # Add context-specific details
        details = []
        
        if rule.conditions and context:
            if 'retry_count' in context:
                details.append(f"retry_count={context['retry_count']}")
            if 'timeout_seconds' in context:
                details.append(f"timeout={context['timeout_seconds']}s")
            if 'connection_count' in context:
                details.append(f"connections={context['connection_count']}")
        
        if issue['raw_metric_value']:
            details.append(f"metric={issue['raw_metric_value']} {issue['raw_metric_unit'] or ''}")
        
        details.append(f"source={issue['detection_source']}")
        
        if details:
            return f"{base_reason} ({', '.join(details)})"
        else:
            return base_reason
    
    def _record_decision(self, decision: Dict[str, Any]) -> bool:
        """
        Record decision in the decision_log table.
        
        Args:
            decision: Decision record to insert
            
        Returns:
            True if successful, False otherwise
        """
        # Create a write-enabled connection for decision recording
        insert_query = """
        INSERT INTO decision_log (
            decision_id, issue_id, decision_type, decision_reason,
            confidence_at_decision, decided_at
        ) VALUES (%s, %s, %s, %s, %s, %s)
        """
        
        try:
            # Use a separate connection with write permissions for decision logging
            config = self.db.config.copy()
            # Remove read-only restriction for decision recording
            
            import mysql.connector
            with mysql.connector.connect(**config) as conn:
                cursor = conn.cursor()
                
                cursor.execute(insert_query, (
                    decision['decision_id'],
                    decision['issue_id'],
                    decision['decision_type'],
                    decision['decision_reason'],
                    decision['confidence_at_decision'],
                    decision['decided_at']
                ))
                
                conn.commit()
                cursor.close()
                
                logger.info(f"Decision recorded: {decision['decision_id']}")
                return True
                
        except Exception as e:
            logger.error(f"Error recording decision {decision['decision_id']}: {e}")
            return False
    
    def get_decision_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about decisions made by the engine.
        
        Returns:
            Dictionary containing decision statistics
        """
        query = """
        SELECT 
            decision_type,
            COUNT(*) as count,
            AVG(confidence_at_decision) as avg_confidence,
            MIN(decided_at) as first_decision,
            MAX(decided_at) as last_decision
        FROM decision_log
        GROUP BY decision_type
        ORDER BY count DESC
        """
        
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor(dictionary=True)
                cursor.execute(query)
                results = cursor.fetchall()
                cursor.close()
                
                stats = {
                    'total_decisions': sum(r['count'] for r in results),
                    'by_type': {},
                    'overall_confidence': 0
                }
                
                total_confidence = 0
                total_count = 0
                
                for result in results:
                    decision_type = result['decision_type']
                    count = result['count']
                    avg_confidence = float(result['avg_confidence']) if result['avg_confidence'] else 0
                    
                    stats['by_type'][decision_type] = {
                        'count': count,
                        'avg_confidence': avg_confidence,
                        'first_decision': result['first_decision'],
                        'last_decision': result['last_decision']
                    }
                    
                    total_confidence += avg_confidence * count
                    total_count += count
                
                if total_count > 0:
                    stats['overall_confidence'] = total_confidence / total_count
                
                return stats
                
        except Exception as e:
            logger.error(f"Error getting decision statistics: {e}")
            return {'error': str(e)}
    
    def validate_decision_integrity(self) -> Dict[str, Any]:
        """
        Validate the integrity of decisions in the system.
        
        Returns:
            Validation results
        """
        validation = {
            'timestamp': datetime.now(),
            'issues_without_decisions': 0,
            'decisions_without_issues': 0,
            'invalid_decision_types': 0,
            'confidence_out_of_range': 0,
            'errors': []
        }
        
        try:
            # Check for issues without decisions
            query1 = """
            SELECT COUNT(*) as count
            FROM detected_issues di
            LEFT JOIN decision_log dl ON di.issue_id = dl.issue_id
            WHERE dl.issue_id IS NULL
            """
            
            with self.db.get_connection() as conn:
                cursor = conn.cursor(dictionary=True)
                
                cursor.execute(query1)
                result = cursor.fetchone()
                validation['issues_without_decisions'] = result['count'] if result else 0
                
                # Check for decisions without issues (orphaned decisions)
                query2 = """
                SELECT COUNT(*) as count
                FROM decision_log dl
                LEFT JOIN detected_issues di ON dl.issue_id = di.issue_id
                WHERE di.issue_id IS NULL
                """
                
                cursor.execute(query2)
                result = cursor.fetchone()
                validation['decisions_without_issues'] = result['count'] if result else 0
                
                # Check for invalid decision types
                valid_types = ['AUTO_HEAL', 'ADMIN_REVIEW', 'ESCALATED']
                query3 = f"""
                SELECT COUNT(*) as count
                FROM decision_log
                WHERE decision_type NOT IN ({','.join(['%s'] * len(valid_types))})
                """
                
                cursor.execute(query3, valid_types)
                result = cursor.fetchone()
                validation['invalid_decision_types'] = result['count'] if result else 0
                
                # Check for confidence scores out of range
                query4 = """
                SELECT COUNT(*) as count
                FROM decision_log
                WHERE confidence_at_decision < 0 OR confidence_at_decision > 1
                """
                
                cursor.execute(query4)
                result = cursor.fetchone()
                validation['confidence_out_of_range'] = result['count'] if result else 0
                
                cursor.close()
                
        except Exception as e:
            error_msg = f"Error validating decision integrity: {e}"
            logger.error(error_msg)
            validation['errors'].append(error_msg)
        
        return validation