// API client for DBMS self-healing backend with security enhancements
import type {
  DetectedIssue,
  AIAnalysis,
  DecisionLog,
  HealingAction,
  AdminReview,
  LearningHistory,
  HealthCheck,
} from '../types/dashboard';
import { DASHBOARD_CONFIG } from './config';

const ALLOWED_API_URLS = ['http://localhost:8002', 'https://localhost:8002'];
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8002';

// Validate API URL for security
if (!ALLOWED_API_URLS.includes(API_BASE_URL)) {
  console.warn('Invalid API URL detected, falling back to default');
}

console.log('API Client initialized with URL:', API_BASE_URL);

// API Response interfaces for type safety
interface APIAnalysisResponse {
  analysis_id: string;
  issue_id: string;
  analyzed_at: string;
  confidence_score: number | string;
  predicted_issue_class: string;
  severity_level: string;
  risk_type: string;
  model_version: string;
  baseline_metric: number | string | null;
  severity_ratio: number | string | null;
}

interface APIDecisionResponse {
  decision_id: string;
  issue_id: string;
  decision_type: string;
  decision_reason: string;
  confidence_at_decision: number | string;
  decided_at: string;
}

interface APILearningResponse {
  learning_id: string;
  decision_id: string;
  issue_type: string;
  action_type: string;
  outcome: string;
  confidence_before: number | string;
  confidence_after: number | string;
  recorded_at: string;
}

interface DatabaseHealthResponse {
  status: string;
  database_stats: Record<string, number>;
  timestamp: string;
}

interface LearningStatsResponse {
  learning_stats: Array<{
    issue_type: string;
    action_type: string;
    total_records: number;
    avg_improvement: number;
    success_rate: number;
  }>;
}

interface ActionStatsResponse {
  action_stats: Array<{
    execution_status: string;
    count: number;
    action_type: string;
  }>;
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

// Exponential backoff utility
class ExponentialBackoff {
  private attempt = 0;
  private readonly maxAttempts: number;
  private readonly baseDelay: number;
  private readonly maxDelay: number;

  constructor(
    maxAttempts = DASHBOARD_CONFIG.API.MAX_RETRIES,
    baseDelay = DASHBOARD_CONFIG.API.BASE_DELAY_MS,
    maxDelay = DASHBOARD_CONFIG.API.MAX_DELAY_MS
  ) {
    this.maxAttempts = maxAttempts;
    this.baseDelay = baseDelay;
    this.maxDelay = maxDelay;
  }

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    while (this.attempt < this.maxAttempts) {
      try {
        const result = await fn();
        this.reset();
        return result;
      } catch (error) {
        this.attempt++;

        if (this.attempt >= this.maxAttempts) {
          this.reset();
          throw error;
        }

        const delay = Math.min(
          this.baseDelay * Math.pow(2, this.attempt - 1),
          this.maxDelay
        );

        // Only retry on network errors, not on 4xx/5xx HTTP errors
        if (
          error instanceof Error &&
          (error.message.includes('fetch') ||
            error.message.includes('Network') ||
            error.message.includes('timeout'))
        ) {
          await new Promise(resolve => setTimeout(resolve, delay));
        } else {
          // Don't retry on HTTP errors
          this.reset();
          throw error;
        }
      }
    }

    throw new Error('Max attempts reached');
  }

  reset() {
    this.attempt = 0;
  }
}

class ApiClient {
  private backoff = new ExponentialBackoff();

  // Safe number parsing following strict protocol
  private safeNumber(v: any): number {
    if (v === null || v === undefined) return 0;
    const num = Number(v);
    return Number.isNaN(num) ? 0 : num;
  }

  // Data processing helpers with proper types
  private processAnalysisData(data: any): AIAnalysis[] {
    console.log("AI ANALYSIS API RAW RESPONSE:", data);

    // Ensure data is an array before processing
    const results = Array.isArray(data) ? data : [];

    return results.map(item => {
      const mapped: AIAnalysis = {
        ...item,
        // confidence_score: use real value, null if absent
        confidence_score: (item.confidence_score !== null && item.confidence_score !== undefined)
          ? this.safeNumber(item.confidence_score)
          : null,
        // severity_ratio and baseline_metric: pass through EXACTLY as returned by API
        // DO NOT apply safeNumber() — it converts null → 0 which masks missing data
        severity_ratio: item.severity_ratio !== undefined ? item.severity_ratio : null,
        baseline_metric: item.baseline_metric !== undefined ? item.baseline_metric : null,
      };
      console.log(
        `Analysis ${item.analysis_id}: ratio=${mapped.severity_ratio}, baseline=${mapped.baseline_metric}`
      );
      return mapped;
    });
  }

  private processDecisionData(data: APIDecisionResponse[]): DecisionLog[] {
    return data.map(item => ({
      ...item,
      confidence_at_decision:
        typeof item.confidence_at_decision === 'string'
          ? parseFloat(item.confidence_at_decision)
          : item.confidence_at_decision,
    }));
  }

  private processLearningData(data: APILearningResponse[]): LearningHistory[] {
    return data.map(item => ({
      learning_id: item.learning_id,
      decision_id: item.decision_id,
      issue_type: item.issue_type,
      action_type: item.action_type,
      outcome: item.outcome,
      confidence_before:
        typeof item.confidence_before === 'string'
          ? parseFloat(item.confidence_before)
          : item.confidence_before,
      confidence_after:
        typeof item.confidence_after === 'string'
          ? parseFloat(item.confidence_after)
          : item.confidence_after,
      recorded_at: item.recorded_at,
    }));
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    return this.backoff.execute(async () => {
      try {
        const controller = new AbortController();
        // Use 60s for writes (stored procedures), 30s for reads
        const timeoutMs = options.method && options.method !== 'GET' ? 60000 : 30000;
        const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
          method: options.method || 'GET',
          headers: {
            'Content-Type': 'application/json',
            'X-Admin-Token': process.env.NEXT_PUBLIC_ADMIN_TOKEN || 'your-api-key-change-in-production-use-strong-random-key',
            ...(options.headers || {}),
          },
          body: options.body,
          signal: controller.signal,
          mode: 'cors',
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
          // Explicitly handle 400, 403 and other client errors
          const errorData = await response.json().catch(() => ({}));
          const errorMessage = errorData.detail || response.statusText;
          
          const error: any = new Error(`API request failed: ${response.status} ${errorMessage}`);
          error.status = response.status;
          throw error;
        }

        return response.json();
      } catch (error: any) {
        // STEP 7: Stop retrying on 400 (Bad Request) and 403 (Forbidden)
        if (error.status === 400 || error.status === 403) {
          console.error(`Stopping retry loop due to client error: ${error.status}`);
          throw error;
        }

        // Enhanced error handling
        if (error instanceof Error) {
          if (error.name === 'AbortError') {
            throw new Error('Request timeout - API server may be unavailable');
          }
          if (error.message.includes('fetch')) {
            throw new Error('Network error - Cannot connect to API server');
          }
        }

        // Sanitize error messages for production
        if (process.env.NODE_ENV === 'production') {
          console.error('API request failed');
        } else {
          console.error(`API request to ${endpoint} failed:`, error);
          console.error(`Trying to connect to: ${API_BASE_URL}${endpoint}`);
        }
        throw error;
      }
    });
  }

  // Issues API
  async getDetectedIssues(): Promise<DetectedIssue[]> {
    return this.request<DetectedIssue[]>('/issues/');
  }

  async getIssueAnalysis(issueId: string): Promise<IssueAnalysis> {
    // Input sanitization
    const sanitizedId = issueId.replace(/[^a-zA-Z0-9-_]/g, '');
    return this.request<IssueAnalysis>(`/issues/${sanitizedId}/analysis`);
  }

  async getIssueDecision(issueId: string): Promise<IssueDecision> {
    const sanitizedId = issueId.replace(/[^a-zA-Z0-9-_]/g, '');
    return this.request<IssueDecision>(`/issues/${sanitizedId}/decision`);
  }

  // AI Analysis API
  async getAllAnalysis(): Promise<AIAnalysis[]> {
    const data = await this.request<APIAnalysisResponse[]>('/analysis/');
    return this.processAnalysisData(data);
  }

  async getAnalysisById(analysisId: string): Promise<AIAnalysis> {
    const sanitizedId = analysisId.replace(/[^a-zA-Z0-9-_]/g, '');
    const data = await this.request<APIAnalysisResponse>(
      `/analysis/${sanitizedId}`
    );
    return this.processAnalysisData([data])[0];
  }

  async getAnalysisByIssue(issueId: string): Promise<AIAnalysis[]> {
    const sanitizedId = issueId.replace(/[^a-zA-Z0-9-_]/g, '');
    const data = await this.request<APIAnalysisResponse[]>(
      `/analysis/issue/${sanitizedId}`
    );
    return this.processAnalysisData(data);
  }

  // Decision Log API
  async getAllDecisions(): Promise<DecisionLog[]> {
    const data = await this.request<APIDecisionResponse[]>('/decisions/');
    return this.processDecisionData(data);
  }

  async getDecisionById(decisionId: string): Promise<DecisionLog> {
    const sanitizedId = decisionId.replace(/[^a-zA-Z0-9-_]/g, '');
    const data = await this.request<APIDecisionResponse>(
      `/decisions/${sanitizedId}`
    );
    return this.processDecisionData([data])[0];
  }

  async getDecisionsByIssue(issueId: string): Promise<DecisionLog[]> {
    const sanitizedId = issueId.replace(/[^a-zA-Z0-9-_]/g, '');
    const data = await this.request<APIDecisionResponse[]>(
      `/decisions/issue/${sanitizedId}`
    );
    return this.processDecisionData(data);
  }

  // Actions API
  async getHealingActions(
    limit?: number,
    status?: string
  ): Promise<HealingAction[]> {
    const params = new URLSearchParams();

    // Input validation
    if (limit && limit > 0 && limit <= 1000) {
      params.append('limit', limit.toString());
    }
    if (status && /^[A-Z_]+$/.test(status)) {
      params.append('status', status);
    }

    const query = params.toString() ? `?${params.toString()}` : '';
    return this.request<HealingAction[]>(`/actions/${query}`);
  }

  async getHealingAction(actionId: string): Promise<HealingAction> {
    const sanitizedId = actionId.replace(/[^a-zA-Z0-9-_]/g, '');
    return this.request<HealingAction>(`/actions/${sanitizedId}`);
  }

  async getActionsByDecision(decisionId: string): Promise<HealingAction[]> {
    const sanitizedId = decisionId.replace(/[^a-zA-Z0-9-_]/g, '');
    return this.request<HealingAction[]>(`/actions/decision/${sanitizedId}`);
  }

  // Admin Reviews API
  async getAllAdminReviews(): Promise<AdminReview[]> {
    return this.request<AdminReview[]>('/admin-reviews/');
  }

  async getAdminReviewById(reviewId: string): Promise<AdminReview> {
    const sanitizedId = reviewId.replace(/[^a-zA-Z0-9-_]/g, '');
    return this.request<AdminReview>(`/admin-reviews/${sanitizedId}`);
  }

  async getReviewsByDecision(decisionId: string): Promise<AdminReview[]> {
    const sanitizedId = decisionId.replace(/[^a-zA-Z0-9-_]/g, '');
    return this.request<AdminReview[]>(
      `/admin-reviews/decision/${sanitizedId}`
    );
  }

  async approveReview(reviewId: string): Promise<any> {
    const sanitizedId = reviewId.replace(/[^a-zA-Z0-9-_]/g, '');
    return this.request<any>(`/admin-reviews/${sanitizedId}/approve`, {
      method: 'POST',
    });
  }

  async rejectReview(reviewId: string): Promise<any> {
    const sanitizedId = reviewId.replace(/[^a-zA-Z0-9-_]/g, '');
    return this.request<any>(`/admin-reviews/${sanitizedId}/reject`, {
      method: 'POST',
    });
  }

  // Learning History API
  async getAllLearningHistory(): Promise<LearningHistory[]> {
    const data = await this.request<APILearningResponse[]>('/learning/');
    return this.processLearningData(data);
  }

  async getLearningRecordById(learningId: string): Promise<LearningHistory> {
    const sanitizedId = learningId.replace(/[^a-zA-Z0-9-_]/g, '');
    const data = await this.request<APILearningResponse>(
      `/learning/${sanitizedId}`
    );
    return this.processLearningData([data])[0];
  }

  async getLearningImprovementStats(): Promise<LearningStatsResponse> {
    return this.request<LearningStatsResponse>('/learning/stats/improvement');
  }

  // Health API
  async getHealthCheck(): Promise<HealthCheck> {
    return this.request<HealthCheck>('/health/');
  }

  async getDatabaseHealth(): Promise<DatabaseHealthResponse> {
    return this.request<DatabaseHealthResponse>('/health/database');
  }

  // Statistics APIs
  async getActionStats(): Promise<ActionStatsResponse> {
    return this.request<ActionStatsResponse>('/actions/stats/summary');
  }
}

export const apiClient = new ApiClient();

// Re-export types for component usage
export type {
  DetectedIssue,
  AIAnalysis,
  DecisionLog,
  HealingAction,
  AdminReview,
  LearningHistory,
} from '../types/dashboard';
