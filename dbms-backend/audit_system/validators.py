class AuditValidators:
    @staticmethod
    def validate_detection(issue):
        if not issue: return False, "No issue found in detected_issues"
        if not issue['issue_type']: return False, "issue_type is null"
        # Check if timestamp is within last 10 seconds
        return True, "Detection Layer: OK"

    @staticmethod
    def validate_decision(decision):
        if not decision: return False, "No decision found"
        if decision[0]['decision_type'] not in ['AUTO_HEAL', 'ADMIN_REVIEW']:
            return False, f"Invalid decision type: {decision[0]['decision_type']}"
        return True, "Decision Layer: OK"

    @staticmethod
    def validate_execution(action):
        if not action: return False, "No healing action recorded"
        if action[0]['execution_status'] not in ['SUCCESS', 'FAILED', 'SKIPPED']:
            return False, "Invalid execution status"
        if action[0]['action_type'] == 'UNKNOWN_ACTION':
            return False, "Action mapping failed (UNKNOWN_ACTION)"
        return True, "Execution Layer: OK"

    @staticmethod
    def validate_verification(action):
        if not action: return False, "No action to verify"
        if action[0]['verification_status'] == 'FAILED':
            return False, "Post-execution verification failed (State did not improve)"
        if action[0]['verification_status'] == 'UNVERIFIED':
            return False, "Verification logic was skipped"
        return True, "Verification Layer: OK"
