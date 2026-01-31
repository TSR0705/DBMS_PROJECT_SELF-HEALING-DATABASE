// API client for DBMS self-healing backend
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export interface DetectedIssue {
  issue_id: string;
  issue_type: string;
  detection_source: string;
  raw_metric_value: number | null;
  detected_at: string;
}

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

export interface HealingAction {
  action_id: string;
  action_type: string;
  execution_status: string;
  executed_at: string;
}

export interface HealthCheck {
  status: string;
  database_connected: boolean;
  timestamp: string;
}

class ApiClient {
  private async request<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${response.statusText}`);
    }

    return response.json();
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

  // Actions API
  async getHealingActions(limit?: number, status?: string): Promise<HealingAction[]> {
    const params = new URLSearchParams();
    if (limit) params.append('limit', limit.toString());
    if (status) params.append('status', status);
    
    const query = params.toString() ? `?${params.toString()}` : '';
    return this.request<HealingAction[]>(`/actions/${query}`);
  }

  async getHealingAction(actionId: string): Promise<HealingAction> {
    return this.request<HealingAction>(`/actions/${actionId}`);
  }

  // Health API
  async getHealthCheck(): Promise<HealthCheck> {
    return this.request<HealthCheck>('/health/');
  }

  async getDatabaseHealth(): Promise<any> {
    return this.request<any>('/health/database');
  }
}

export const apiClient = new ApiClient();