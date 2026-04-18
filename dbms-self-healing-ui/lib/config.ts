/**
 * Centralized configuration for the DBMS Dashboard
 * Controls timing, limits, and system-wide constants
 */

export const DASHBOARD_CONFIG = {
  // Polling intervals
  REFRESH_INTERVAL_MS: 10000,
  
  // Data display limits
  LIMITS: {
    RECENT_ISSUES: 10,
    RECENT_ANALYSIS: 10,
    RECENT_DECISIONS: 10,
    RECENT_LEARNING: 10,
    RECENT_REVIEWS: 50, // Higher limit for reviews to prevent hiding pending tasks
    RECENT_EVENTS: 10,
  },
  
  // API settings
  API: {
    MAX_RETRIES: 3,
    BASE_DELAY_MS: 1000,
    MAX_DELAY_MS: 10000,
  },
  
  // Visual thresholds
  THRESHOLDS: {
    CONFIDENCE_HIGH: 0.8,
    CONFIDENCE_MEDIUM: 0.6,
    SEVERITY_RATIO_CRITICAL: 1.5,
  }
};
