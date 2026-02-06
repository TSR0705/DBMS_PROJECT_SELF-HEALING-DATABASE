"""
DBMS Admin Review Engine
Implements admin review pipeline for ADMIN_REVIEW decisions.

This engine:
1. Processes ADMIN_REVIEW decisions from decision_log
2. Creates admin review records with recommendations
3. Tracks admin override capabilities
4. Provides escalation workflow for complex issues

All admin reviews are tracked for audit and learning purposes.
"""

import logging
import uuid
from datetime import datetime
from typing import List, Dict, Optional, Any

from ..database.connection import DatabaseConnection
from ..rules.healing_rulebook import HealingRulebook, ActionType

logger = logging.getLogger(__name__)

class AdminReviewEngine:
    """
    Admin review engine for DBMS self-healing.
    
    Manages the escalation of issues that require human intervention,
    providing recommendations and tracking admin decisions.
    """
    
    def __init__(self):
        self.db = DatabaseConnection()
        self.rulebook = HealingRulebook()
        
    def process_admin_review_decisions(self) -> Dict[str, Any]:
        """
        Process all unprocessed ADMIN_REVIEW decisions and create review records.
        
        Returns:
            Dictionary containing processing results and statistics
        """
        logger.info("Starting admin review engine processing...")
        
        results = {
            'timestamp': datetime.now(),
            'decisions_processed': 0,
            'reviews_created': 0,
            'high_priority_reviews': 0,
            'errors': [],
            'reviews': []
        }
        
        try:
            # Get unprocessed ADMIN_REVIEW decisions
            admin_review_decisions = self._get_unprocessed_admin_review_decisions()
            results['decisions_processed'] = len(admin_review_decisions)
            
            logger.info(f"Found {len(admin_review_decisions)} unprocessed ADMIN_REVIEW decisions")
            
            # Process each decision
            for decision in admin_review_decisions:
                try:
                    review = self._create_admin_review(decision)
                    if review:
                        self._record_admin_review(review)
                        results['reviews'].append(review)
                        results['reviews_created'] += 1
                        
                        if review['priority'] == 'HIGH':
                            results['high_priority_reviews'] += 1
                            
                        logger.info(f"Admin review created for decision {decision['decision_id']}: {review['priority']} priority")
                    
                except Exception as e:
                    error_msg = f"Error processing decision {decision.get('decision_id', 'unknown')}: {str(e)}"
                    logger.error(error_msg)
                    results['errors'].append(error_msg)
            
            logger.info(f"Admin review engine completed: {results['reviews_created']} reviews created")
            
        except Exception as e:
            error_msg = f"Critical error in admin review engine: {str(e)}"
            logger.error(error_msg)
            results['errors'].append(error_msg)
        
        return results
    
    def _get_unprocessed_admin_review_decisions(self) -> List[Dict[str, Any]]:
        """
        Get ADMIN_REVIEW decisions that haven't been processed yet (no admin review record).
        
        Returns:
            List of unprocessed ADMIN_REVIEW decision records
        """
        query = """
        SELECT 
            dl.decision_id,
            dl.issue_id,
            dl.decision_type,
            dl.decision_reason,
            dl.confidence_at_decision,
            dl.decided_at,
            di.issue_type,
            di.detection_source,
            di.raw_metric_value,
            di.raw_metric_unit,
            di.detected_at
        FROM decision_log dl
        JOIN detected_issues di ON dl.issue_id = di.issue_id
        LEFT JOIN admin_reviews ar ON dl.decision_id = ar.decision_id
        WHERE dl.decision_type = 'ADMIN_REVIEW'
        AND ar.decision_id IS NULL
        ORDER BY dl.decided_at ASC
        """
        
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor(dictionary=True)
                cursor.execute(query)
                results = cursor.fetchall()
                cursor.close()
                return results
                
        except Exception as e:
            logger.error(f"Error fetching unprocessed ADMIN_REVIEW decisions: {e}")
            return []
    
    def _create_admin_review(self, decision: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Create an admin review record for an ADMIN_REVIEW decision.
        
        Args:
            decision: Decision record from decision_log
            
        Returns:
            Admin review record to be inserted into admin_reviews, or None if error
        """
        try:
            decision_id = str(decision['decision_id'])
            issue_type = decision['issue_type']
            
            # Generate recommendations based on issue type
            recommendations = self._generate_recommendations(decision)
            
            # Determine priority based on issue characteristics
            priority = self._determine_priority(decision)
            
            # Create admin review record
            review = {
                'review_id': str(uuid.uuid4()),
                'decision_id': decision_id,
                'admin_action': 'PENDING',
                'admin_comment': None,
                'override_flag': False,
                'reviewed_at': datetime.now(),
                'priority': priority,
                'recommendations': recommendations,
                'escalation_reason': decision['decision_reason'],
                'issue_context': {
                    'issue_type': issue_type,
                    'detection_source': decision['detection_source'],
                    'metric_value': float(decision['raw_metric_value']) if decision['raw_metric_value'] else None,
                    'metric_unit': decision['raw_metric_unit'],
                    'detected_at': decision['detected_at'],
                    'decided_at': decision['decided_at']
                }
            }
            
            logger.info(f"Admin review created for decision {decision_id}: {priority} priority - {issue_type}")
            
            return review
            
        except Exception as e:
            logger.error(f"Error creating admin review for decision {decision.get('decision_id', 'unknown')}: {e}")
            return None
    
    def _generate_recommendations(self, decision: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate specific recommendations based on issue type and context.
        
        Args:
            decision: Decision context
            
        Returns:
            Dictionary containing recommendations
        """
        issue_type = decision['issue_type']
        metric_value = float(decision['raw_metric_value']) if decision['raw_metric_value'] else 0
        detection_source = decision['detection_source']
        
        recommendations = {
            'primary_action': '',
            'secondary_actions': [],
            'investigation_steps': [],
            'prevention_measures': [],
            'estimated_effort': 'MEDIUM',
            'urgency': 'MEDIUM'
        }
        
        if issue_type == 'SLOW_QUERY':
            recommendations.update({
                'primary_action': 'Analyze query execution plan and optimize',
                'secondary_actions': [
                    'Review table indexes',
                    'Consider query rewriting',
                    'Evaluate table statistics'
                ],
                'investigation_steps': [
                    'Run EXPLAIN on the slow query',
                    'Check for missing indexes',
                    'Analyze table cardinality',
                    'Review query patterns'
                ],
                'prevention_measures': [
                    'Implement query performance monitoring',
                    'Add appropriate indexes',
                    'Set up query review process',
                    'Consider query caching'
                ],
                'estimated_effort': 'HIGH' if metric_value > 30 else 'MEDIUM',
                'urgency': 'HIGH' if metric_value > 60 else 'MEDIUM'
            })
        
        elif issue_type == 'CONNECTION_OVERLOAD':
            recommendations.update({
                'primary_action': 'Analyze connection usage patterns and increase limits if needed',
                'secondary_actions': [
                    'Implement connection pooling',
                    'Review application connection management',
                    'Consider connection timeout adjustments'
                ],
                'investigation_steps': [
                    'Monitor connection patterns over time',
                    'Identify applications with high connection usage',
                    'Check for connection leaks',
                    'Review max_connections setting'
                ],
                'prevention_measures': [
                    'Implement proper connection pooling',
                    'Set connection timeouts',
                    'Monitor connection metrics',
                    'Educate developers on connection best practices'
                ],
                'estimated_effort': 'MEDIUM',
                'urgency': 'HIGH' if metric_value > 80 else 'MEDIUM'
            })
        
        elif issue_type == 'TRANSACTION_FAILURE':
            recommendations.update({
                'primary_action': 'Investigate root cause of transaction failures',
                'secondary_actions': [
                    'Review application error handling',
                    'Check for resource constraints',
                    'Analyze transaction patterns'
                ],
                'investigation_steps': [
                    'Review MySQL error logs',
                    'Check for lock contention',
                    'Analyze transaction isolation levels',
                    'Monitor system resources'
                ],
                'prevention_measures': [
                    'Implement proper error handling',
                    'Optimize transaction scope',
                    'Monitor transaction metrics',
                    'Consider retry mechanisms'
                ],
                'estimated_effort': 'HIGH',
                'urgency': 'HIGH'
            })
        
        elif issue_type == 'LOCK_WAIT':
            recommendations.update({
                'primary_action': 'Analyze lock contention patterns and optimize transaction design',
                'secondary_actions': [
                    'Review transaction isolation levels',
                    'Optimize query order in transactions',
                    'Consider lock timeout adjustments'
                ],
                'investigation_steps': [
                    'Monitor InnoDB lock waits',
                    'Analyze transaction patterns',
                    'Check for long-running transactions',
                    'Review application logic'
                ],
                'prevention_measures': [
                    'Minimize transaction scope',
                    'Use consistent lock ordering',
                    'Implement timeout handling',
                    'Monitor lock metrics'
                ],
                'estimated_effort': 'HIGH',
                'urgency': 'HIGH' if metric_value > 30 else 'MEDIUM'
            })
        
        else:
            # Unknown issue type
            recommendations.update({
                'primary_action': f'Investigate unknown issue type: {issue_type}',
                'secondary_actions': [
                    'Review detection source logs',
                    'Consult DBMS documentation',
                    'Consider escalation to vendor support'
                ],
                'investigation_steps': [
                    'Gather detailed system information',
                    'Review recent system changes',
                    'Check vendor documentation',
                    'Consult with DBMS experts'
                ],
                'prevention_measures': [
                    'Enhance monitoring coverage',
                    'Update issue type definitions',
                    'Improve detection rules'
                ],
                'estimated_effort': 'HIGH',
                'urgency': 'HIGH'
            })
        
        return recommendations
    
    def _determine_priority(self, decision: Dict[str, Any]) -> str:
        """
        Determine priority level for admin review based on issue characteristics.
        
        Args:
            decision: Decision context
            
        Returns:
            Priority level: HIGH, MEDIUM, or LOW
        """
        issue_type = decision['issue_type']
        metric_value = float(decision['raw_metric_value']) if decision['raw_metric_value'] else 0
        
        # High priority conditions
        if issue_type in ['TRANSACTION_FAILURE', 'CONNECTION_OVERLOAD']:
            return 'HIGH'
        
        if issue_type == 'SLOW_QUERY' and metric_value > 60:  # > 60 seconds
            return 'HIGH'
        
        if issue_type == 'LOCK_WAIT' and metric_value > 30:  # > 30 seconds
            return 'HIGH'
        
        # Medium priority conditions
        if issue_type == 'SLOW_QUERY' and metric_value > 10:  # > 10 seconds
            return 'MEDIUM'
        
        if issue_type == 'LOCK_WAIT' and metric_value > 5:  # > 5 seconds
            return 'MEDIUM'
        
        # Default to LOW priority
        return 'LOW'
    
    def _record_admin_review(self, review: Dict[str, Any]) -> bool:
        """
        Record admin review in the admin_reviews table.
        
        Args:
            review: Admin review record to insert
            
        Returns:
            True if successful, False otherwise
        """
        insert_query = """
        INSERT INTO admin_reviews (
            review_id, decision_id, admin_action, admin_comment,
            override_flag, reviewed_at
        ) VALUES (%s, %s, %s, %s, %s, %s)
        """
        
        try:
            # Use a separate connection with write permissions for review logging
            config = self.db.config.copy()
            
            import mysql.connector
            with mysql.connector.connect(**config) as conn:
                cursor = conn.cursor()
                
                cursor.execute(insert_query, (
                    review['review_id'],
                    review['decision_id'],
                    review['admin_action'],
                    review['admin_comment'],
                    review['override_flag'],
                    review['reviewed_at']
                ))
                
                conn.commit()
                cursor.close()
                
                logger.info(f"Admin review recorded: {review['review_id']}")
                return True
                
        except Exception as e:
            logger.error(f"Error recording admin review {review['review_id']}: {e}")
            return False
    
    def get_pending_reviews(self) -> List[Dict[str, Any]]:
        """
        Get all pending admin reviews that require attention.
        
        Returns:
            List of pending admin review records
        """
        query = """
        SELECT 
            ar.review_id,
            ar.decision_id,
            ar.admin_action,
            ar.reviewed_at,
            dl.issue_id,
            dl.decision_reason,
            di.issue_type,
            di.detection_source,
            di.raw_metric_value,
            di.raw_metric_unit,
            di.detected_at
        FROM admin_reviews ar
        JOIN decision_log dl ON ar.decision_id = dl.decision_id
        JOIN detected_issues di ON dl.issue_id = di.issue_id
        WHERE ar.admin_action = 'PENDING'
        ORDER BY ar.reviewed_at ASC
        """
        
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor(dictionary=True)
                cursor.execute(query)
                results = cursor.fetchall()
                cursor.close()
                return results
                
        except Exception as e:
            logger.error(f"Error fetching pending reviews: {e}")
            return []
    
    def get_admin_review_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about admin reviews in the system.
        
        Returns:
            Dictionary containing admin review statistics
        """
        query = """
        SELECT 
            admin_action,
            COUNT(*) as count,
            MIN(reviewed_at) as first_review,
            MAX(reviewed_at) as last_review
        FROM admin_reviews
        GROUP BY admin_action
        ORDER BY count DESC
        """
        
        try:
            with self.db.get_connection() as conn:
                cursor = conn.cursor(dictionary=True)
                cursor.execute(query)
                results = cursor.fetchall()
                cursor.close()
                
                stats = {
                    'total_reviews': sum(r['count'] for r in results),
                    'by_action': {},
                    'pending_count': 0,
                    'completed_count': 0
                }
                
                for result in results:
                    action = result['admin_action']
                    count = result['count']
                    
                    stats['by_action'][action] = {
                        'count': count,
                        'first_review': result['first_review'],
                        'last_review': result['last_review']
                    }
                    
                    if action == 'PENDING':
                        stats['pending_count'] = count
                    else:
                        stats['completed_count'] += count
                
                return stats
                
        except Exception as e:
            logger.error(f"Error getting admin review statistics: {e}")
            return {'error': str(e)}
    
    def simulate_admin_action(self, review_id: str, action: str, comment: str = None, override: bool = False) -> bool:
        """
        Simulate an admin taking action on a review (for testing purposes).
        
        Args:
            review_id: Review identifier
            action: Admin action taken
            comment: Optional admin comment
            override: Whether this overrides the original decision
            
        Returns:
            True if successful, False otherwise
        """
        update_query = """
        UPDATE admin_reviews 
        SET admin_action = %s, admin_comment = %s, override_flag = %s, reviewed_at = %s
        WHERE review_id = %s
        """
        
        try:
            config = self.db.config.copy()
            
            import mysql.connector
            with mysql.connector.connect(**config) as conn:
                cursor = conn.cursor()
                
                cursor.execute(update_query, (
                    action,
                    comment,
                    override,
                    datetime.now(),
                    review_id
                ))
                
                conn.commit()
                cursor.close()
                
                logger.info(f"Admin action simulated for review {review_id}: {action}")
                return True
                
        except Exception as e:
            logger.error(f"Error simulating admin action for review {review_id}: {e}")
            return False