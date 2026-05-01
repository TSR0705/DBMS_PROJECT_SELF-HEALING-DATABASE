/**
 * Centralized configuration for the DBMS Dashboard
 * Controls timing, limits, and system-wide constants
 */

export const DASHBOARD_CONFIG = {
  // Polling intervals
  REFRESH_INTERVAL_MS: 3000,
  
  // Data display limits - Extended for better visibility
  LIMITS: {
    RECENT_ISSUES: 100,      // Increased from 10 to 100
    RECENT_ANALYSIS: 100,    // Increased from 10 to 100
    RECENT_DECISIONS: 100,   // Increased from 10 to 100
    RECENT_LEARNING: 100,    // Increased from 10 to 100
    RECENT_REVIEWS: 100,     // Increased from 50 to 100
    RECENT_EVENTS: 100,      // Increased from 10 to 100
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
