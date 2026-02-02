// API client for DBMS self-healing backend
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

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

// Legacy interfaces for backward compatibility
export interface IssueAnalysis {
  issue_id: string;
  predicted_issue_class: string;
  severity_level: string;
  confidence_score: number;
  analyzed_at: string;
}

export interface IssueDecision {
  issue_id: string;
  decision_type: string;
  decision_reason: string;
  decided_at: string;
}

class ApiClient {
  private async request<T>(endpoint: string): Promise<T> {
    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(
          `API request failed: ${response.status} ${response.statusText}`
        );
      }

      return response.json();
    } catch (error) {
      console.error(`API request to ${endpoint} failed:`, error);
      throw error;
    }
  }

  // Issues API
  async getDetectedIssues(): Promise<DetectedIssue[]> {
    return this.request<DetectedIssue[]>('/issues/');
  }

  async getIssueAnalysis(issueId: string): Promise<IssueAnalysis> {
    return this.request<IssueAnalysis>(`/issues/${issueId}/analysis`);
  }

  async getIssueDecision(issueId: string): Promise<IssueDecision> {
    return this.request<IssueDecision>(`/issues/${issueId}/decision`);
  }

  // AI Analysis API
  async getAllAnalysis(): Promise<AIAnalysis[]> {
    return this.request<AIAnalysis[]>('/analysis/');
  }

  async getAnalysisById(analysisId: string): Promise<AIAnalysis> {
    return this.request<AIAnalysis>(`/analysis/${analysisId}`);
  }

  async getAnalysisByIssue(issueId: string): Promise<AIAnalysis[]> {
    return this.request<AIAnalysis[]>(`/analysis/issue/${issueId}`);
  }

  // Decision Log API
  async getAllDecisions(): Promise<DecisionLog[]> {
    return this.request<DecisionLog[]>('/decisions/');
  }

  async getDecisionById(decisionId: string): Promise<DecisionLog> {
    return this.request<DecisionLog>(`/decisions/${decisionId}`);
  }

  async getDecisionsByIssue(issueId: string): Promise<DecisionLog[]> {
    return this.request<DecisionLog[]>(`/decisions/issue/${issueId}`);
  }

  // Actions API
  async getHealingActions(
    limit?: number,
    status?: string
  ): Promise<HealingAction[]> {
    const params = new URLSearchParams();
    if (limit) params.append('limit', limit.toString());
    if (status) params.append('status', status);

    const query = params.toString() ? `?${params.toString()}` : '';
    return this.request<HealingAction[]>(`/actions/${query}`);
  }

  async getHealingAction(actionId: string): Promise<HealingAction> {
    return this.request<HealingAction>(`/actions/${actionId}`);
  }

  async getActionsByDecision(decisionId: string): Promise<HealingAction[]> {
    return this.request<HealingAction[]>(`/actions/decision/${decisionId}`);
  }

  // Admin Reviews API
  async getAllAdminReviews(): Promise<AdminReview[]> {
    return this.request<AdminReview[]>('/admin-reviews/');
  }

  async getAdminReviewById(reviewId: string): Promise<AdminReview> {
    return this.request<AdminReview>(`/admin-reviews/${reviewId}`);
  }

  async getReviewsByDecision(decisionId: string): Promise<AdminReview[]> {
    return this.request<AdminReview[]>(`/admin-reviews/decision/${decisionId}`);
  }

  // Learning History API
  async getAllLearningHistory(): Promise<LearningHistory[]> {
    return this.request<LearningHistory[]>('/learning/');
  }

  async getLearningRecordById(learningId: string): Promise<LearningHistory> {
    return this.request<LearningHistory>(`/learning/${learningId}`);
  }

  async getLearningImprovementStats(): Promise<any> {
    return this.request<any>('/learning/stats/improvement');
  }

  // Health API
  async getHealthCheck(): Promise<HealthCheck> {
    return this.request<HealthCheck>('/health/');
  }

  async getDatabaseHealth(): Promise<any> {
    return this.request<any>('/health/database');
  }

  // Statistics APIs
  async getActionStats(): Promise<any> {
    return this.request<any>('/actions/stats/summary');
  }
}

export const apiClient = new ApiClient();
