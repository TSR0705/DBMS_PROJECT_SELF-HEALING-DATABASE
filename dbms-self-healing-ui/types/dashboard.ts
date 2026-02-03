// Shared TypeScript interfaces for DBMS Dashboard
// These types ensure type safety across all components

export interface DetectedIssue {
  issue_id: string;
  issue_type: string;
  detection_source: string;
  raw_metric_value: number | null;
  raw_metric_unit: string | null;
  detected_at: string;
}

export interface AIAnalysis {
  analysis_id: string;
  issue_id: string;
  predicted_issue_class: string;
  severity_level: string;
  risk_type: string;
  confidence_score: number;
  model_version: string;
  analyzed_at: string;
}

export interface DecisionLog {
  decision_id: string;
  issue_id: string;
  decision_type: string;
  decision_reason: string;
  confidence_at_decision: number;
  decided_at: string;
}

export interface HealingAction {
  action_id: string;
  decision_id: string;
  action_type: string;
  execution_mode: string;
  executed_by: string;
  execution_status: string;
  executed_at: string;
}

export interface AdminReview {
  review_id: string;
  decision_id: string;
  admin_action: string;
  admin_comment: string | null;
  override_flag: boolean;
  reviewed_at: string;
}

export interface LearningHistory {
  learning_id: string;
  issue_type: string;
  action_type: string;
  outcome: string;
  confidence_before: number;
  confidence_after: number;
  recorded_at: string;
}

export interface HealthCheck {
  status: string;
  database_connected: boolean;
  timestamp: string;
}

// System metrics interface for real-time service
export interface SystemMetrics {
  totalIssues: number;
  totalAnalysis: number;
  totalDecisions: number;
  totalActions: number;
  totalReviews: number;
  totalLearning: number;
  isConnected: boolean;
  lastUpdate: Date;
  uptime: string;
  autoHealSuccessRate: number;
  issuesResolved: number;
  detectionTime: string;
  connectionStatus: 'connected' | 'disconnected' | 'error' | 'connecting';
  lastError?: string;
}

export interface RealtimeData {
  systemMetrics: SystemMetrics;
  recentIssues: DetectedIssue[];
  recentActions: HealingAction[];
  recentAnalysis: AIAnalysis[];
  recentDecisions: DecisionLog[];
  recentLearning: LearningHistory[];
  recentReviews: AdminReview[];
}