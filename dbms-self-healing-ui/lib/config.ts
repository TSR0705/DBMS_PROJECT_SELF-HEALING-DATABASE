/**
 * Centralized configuration for the DBMS Dashboard
 * Controls timing, limits, and system-wide constants
 */

export const DASHBOARD_CONFIG = {
  // Polling intervals
  REFRESH_INTERVAL_MS: 3000,
  
  // Data display limits - Optimized for performance and visibility
  LIMITS: {
    RECENT_ISSUES: 50,       // Balanced: enough history without overwhelming UI
    RECENT_ANALYSIS: 50,     // Balanced: sufficient for analysis trends
    RECENT_DECISIONS: 50,    // Balanced: good decision history visibility
    RECENT_LEARNING: 30,     // Lower: learning records are less frequently accessed
    RECENT_REVIEWS: 100,     // Higher: admins need to see all pending reviews
    RECENT_EVENTS: 50,       // Balanced: good pipeline visibility
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
