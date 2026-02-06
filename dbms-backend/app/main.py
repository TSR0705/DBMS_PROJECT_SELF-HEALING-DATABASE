"""
Flask application for DBMS self-healing pipeline.
Provides read-only API access to DBMS monitoring and healing data.
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import logging
import os
from datetime import datetime
import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create Flask application
app = Flask(__name__)
CORS(app, origins="*", allow_headers="*", methods=["GET", "POST", "OPTIONS"])

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', 'Tsr@2007'),
    'database': os.getenv('DB_NAME', 'dbms_self_healing'),
}

def get_db_connection():
    """Get database connection."""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        logger.error(f"Database connection error: {e}")
        raise Exception("Database connection failed")

def execute_query(query, params=None):
    """Execute a read-only query and return results."""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(query, params)
        results = cursor.fetchall()
        cursor.close()
        return results
    except Error as e:
        logger.error(f"Query execution error: {e}")
        raise Exception("Query execution failed")
    finally:
        if connection and connection.is_connected():
            connection.close()

def serialize_datetime(obj):
    """Convert datetime objects to ISO format strings."""
    if isinstance(obj, datetime):
        return obj.isoformat()
    return obj

def process_results(results):
    """Process query results to handle datetime serialization."""
    processed = []
    for result in results:
        processed_result = {}
        for key, value in result.items():
            processed_result[key] = serialize_datetime(value)
        processed.append(processed_result)
    return processed

@app.route('/')
def root():
    """API root endpoint."""
    return jsonify({
        "name": "DBMS Self-Healing API",
        "version": "1.0.0",
        "description": "Read-only API for DBMS self-healing pipeline data",
        "timestamp": datetime.utcnow().isoformat(),
        "status": "operational"
    })

@app.route('/health')
def health_check():
    """Health check endpoint."""
    try:
        connection = get_db_connection()
        if connection.is_connected():
            connection.close()
            return jsonify({
                "status": "healthy",
                "database_connected": True,
                "timestamp": datetime.utcnow().isoformat()
            })
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "database_connected": False,
            "timestamp": datetime.utcnow().isoformat(),
            "error": str(e)
        }), 500

@app.route('/health/database')
def database_health():
    """Database health check with detailed information."""
    try:
        query = """
        SELECT 
            (SELECT COUNT(*) FROM detected_issues) as total_issues,
            (SELECT COUNT(*) FROM ai_analysis) as total_analysis,
            (SELECT COUNT(*) FROM decision_log) as total_decisions,
            (SELECT COUNT(*) FROM healing_actions) as total_actions,
            (SELECT COUNT(*) FROM admin_reviews) as total_reviews,
            (SELECT COUNT(*) FROM learning_history) as total_learning
        """
        
        results = execute_query(query)
        stats = results[0] if results else {}
        
        return jsonify({
            "status": "connected",
            "timestamp": datetime.utcnow().isoformat(),
            "database_stats": stats
        })
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return jsonify({"error": "Database health check failed"}), 500

@app.route('/issues/')
def get_detected_issues():
    """Get all detected issues."""
    query = """
    SELECT issue_id, issue_type, detection_source, raw_metric_value, 
           raw_metric_unit, detected_at
    FROM detected_issues 
    ORDER BY detected_at DESC 
    LIMIT 100
    """
    
    try:
        results = execute_query(query)
        return jsonify(process_results(results))
    except Exception as e:
        logger.error(f"Failed to fetch detected issues: {e}")
        return jsonify({"error": "Failed to retrieve detected issues"}), 500

@app.route('/analysis/')
def get_all_analysis():
    """Get all AI analysis results."""
    query = """
    SELECT analysis_id, issue_id, predicted_issue_class, severity_level,
           risk_type, confidence_score, model_version, analyzed_at
    FROM ai_analysis 
    ORDER BY analyzed_at DESC 
    LIMIT 100
    """
    
    try:
        results = execute_query(query)
        return jsonify(process_results(results))
    except Exception as e:
        logger.error(f"Failed to fetch analysis: {e}")
        return jsonify({"error": "Failed to retrieve analysis"}), 500

@app.route('/decisions/')
def get_all_decisions():
    """Get all decision log entries."""
    query = """
    SELECT decision_id, issue_id, decision_type, decision_reason,
           confidence_at_decision, decided_at
    FROM decision_log 
    ORDER BY decided_at DESC 
    LIMIT 100
    """
    
    try:
        results = execute_query(query)
        return jsonify(process_results(results))
    except Exception as e:
        logger.error(f"Failed to fetch decisions: {e}")
        return jsonify({"error": "Failed to retrieve decisions"}), 500

@app.route('/actions/')
def get_healing_actions():
    """Get all healing actions."""
    query = """
    SELECT action_id, decision_id, action_type, execution_mode,
           executed_by, execution_status, executed_at
    FROM healing_actions 
    ORDER BY executed_at DESC 
    LIMIT 100
    """
    
    try:
        results = execute_query(query)
        return jsonify(process_results(results))
    except Exception as e:
        logger.error(f"Failed to fetch actions: {e}")
        return jsonify({"error": "Failed to retrieve actions"}), 500

@app.route('/admin-reviews/')
def get_admin_reviews():
    """Get all admin reviews."""
    query = """
    SELECT review_id, decision_id, review_priority, review_status,
           admin_action, admin_notes, admin_user, reviewed_at, created_at
    FROM admin_reviews 
    ORDER BY created_at DESC 
    LIMIT 100
    """
    
    try:
        results = execute_query(query)
        return jsonify(process_results(results))
    except Exception as e:
        logger.error(f"Failed to fetch admin reviews: {e}")
        return jsonify({"error": "Failed to retrieve admin reviews"}), 500

@app.route('/learning/')
def get_learning_history():
    """Get all learning history."""
    query = """
    SELECT learning_id, issue_type, action_type, outcome,
           confidence_before, confidence_after, recorded_at
    FROM learning_history 
    ORDER BY recorded_at DESC 
    LIMIT 100
    """
    
    try:
        results = execute_query(query)
        return jsonify(process_results(results))
    except Exception as e:
        logger.error(f"Failed to fetch learning history: {e}")
        return jsonify({"error": "Failed to retrieve learning history"}), 500

@app.route('/learning/stats/improvement')
def get_learning_improvement_stats():
    """Get learning improvement statistics."""
    query = """
    SELECT 
        issue_type,
        action_type,
        COUNT(*) as total_records,
        AVG(confidence_after - confidence_before) as avg_improvement,
        SUM(CASE WHEN outcome = 'RESOLVED' THEN 1 ELSE 0 END) / COUNT(*) as success_rate
    FROM learning_history 
    GROUP BY issue_type, action_type
    ORDER BY avg_improvement DESC
    LIMIT 10
    """
    
    try:
        results = execute_query(query)
        return jsonify({
            "learning_stats": process_results(results)
        })
    except Exception as e:
        logger.error(f"Failed to fetch learning stats: {e}")
        return jsonify({"error": "Failed to retrieve learning statistics"}), 500

@app.route('/actions/stats/summary')
def get_action_stats():
    """Get action statistics summary."""
    query = """
    SELECT 
        execution_status,
        COUNT(*) as count,
        action_type
    FROM healing_actions 
    GROUP BY execution_status, action_type
    ORDER BY count DESC
    """
    
    try:
        results = execute_query(query)
        return jsonify({
            "action_stats": process_results(results)
        })
    except Exception as e:
        logger.error(f"Failed to fetch action stats: {e}")
        return jsonify({"error": "Failed to retrieve action statistics"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8002, debug=True)