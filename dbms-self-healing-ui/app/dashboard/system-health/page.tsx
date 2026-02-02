'use client';

import { useEffect, useState } from "react";
import { Section } from "@/components/ui-dbms/Section";
import { StatsCard } from "@/components/ui-dbms/StatsCard";
import { apiClient, HealthCheck } from "@/lib/api";

// Ultra-modern System Health Dashboard with advanced visual effects
export default function SystemHealth() {
  const [healthData, setHealthData] = useState<HealthCheck | null>(null);
  const [databaseHealth, setDatabaseHealth] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchHealthData = async () => {
      try {
        setLoading(true);
        const [health, dbHealth] = await Promise.all([
          apiClient.getHealthCheck(),
          apiClient.getDatabaseHealth()
        ]);
        setHealthData(health);
        setDatabaseHealth(dbHealth);
        setError(null);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch health data');
        console.error('Error fetching health data:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchHealthData();
    
    // Set up polling for real-time updates every 10 seconds
    const interval = setInterval(fetchHealthData, 10000);
    
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        {/* Loading skeleton with shimmer effect */}
        <div className="space-y-6">
          <div className="shimmer h-16 rounded-2xl"></div>
          <div className="shimmer h-8 rounded-xl w-2/3"></div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="shimmer h-40 rounded-2xl"></div>
            ))}
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {[...Array(2)].map((_, i) => (
              <div key={i} className="shimmer h-64 rounded-2xl"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-8 animate-fade-in">
        {/* Enhanced header */}
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold bg-gradient-to-r from-slate-900 via-blue-900 to-indigo-900 bg-clip-text text-transparent">
            System Health
          </h1>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            Real-time system health monitoring and performance metrics
          </p>
        </div>
        
        {/* Enhanced error state */}
        <div className="max-w-2xl mx-auto">
          <div className="bg-gradient-to-br from-red-50 to-rose-50 border border-red-200 rounded-2xl p-8 shadow-lg">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-red-500 rounded-2xl flex items-center justify-center shadow-lg">
                <svg className="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
                </svg>
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold text-red-900 mb-2">Health Check Failed</h3>
                <p className="text-red-700">{error}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  const isHealthy = healthData?.status === 'healthy';
  const isDatabaseConnected = healthData?.database_connected;

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Ultra-modern header with gradient effects */}
      <div className="text-center space-y-6 relative">
        <div className="absolute inset-0 bg-gradient-to-r from-green-600/10 via-blue-600/10 to-indigo-600/10 rounded-3xl blur-3xl"></div>
        <div className="relative z-10 py-8">
          <h1 className="text-5xl font-black bg-gradient-to-r from-slate-900 via-blue-900 to-indigo-900 bg-clip-text text-transparent mb-4">
            System Health
          </h1>
          <p className="text-xl text-slate-600 max-w-3xl mx-auto leading-relaxed">
            Real-time system health monitoring and performance metrics with intelligent diagnostics
          </p>
          
          {/* Status indicator */}
          <div className="flex items-center justify-center space-x-3 mt-6">
            <div className={`flex items-center space-x-2 backdrop-blur-xl rounded-full px-6 py-3 shadow-lg border ${
              isHealthy 
                ? 'bg-green-50/80 border-green-200/50' 
                : 'bg-red-50/80 border-red-200/50'
            }`}>
              <div className={`w-3 h-3 rounded-full shadow-lg ${
                isHealthy ? 'bg-green-400 animate-pulse shadow-green-400/50' : 'bg-red-400 shadow-red-400/50'
              }`}></div>
              <span className={`text-sm font-bold ${
                isHealthy ? 'text-green-700' : 'text-red-700'
              }`}>
                {healthData?.status?.toUpperCase() || 'UNKNOWN'}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Enhanced health status cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatsCard
          title="API Status"
          value={healthData?.status?.toUpperCase() || 'Unknown'}
          subtitle="System availability"
          color={isHealthy ? 'green' : 'red'}
          icon={
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
        />

        <StatsCard
          title="Database"
          value={isDatabaseConnected ? 'Connected' : 'Disconnected'}
          subtitle="Connection status"
          color={isDatabaseConnected ? 'blue' : 'red'}
          icon={
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4" />
            </svg>
          }
        />

        <StatsCard
          title="Last Check"
          value={healthData?.timestamp ? new Date(healthData.timestamp).toLocaleTimeString() : 'N/A'}
          subtitle="Health monitoring"
          color="purple"
          icon={
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
        />
      </div>

      {/* Database performance metrics with enhanced styling */}
      {databaseHealth && (
        <Section
          title="Database Performance"
          description="Detailed database connectivity and performance metrics with real-time analysis"
        >
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Connection details card */}
            <div className="bg-gradient-to-br from-white/80 to-blue-50/80 backdrop-blur-xl rounded-2xl border border-white/20 shadow-xl p-8">
              <h4 className="text-xl font-bold text-slate-900 mb-6 flex items-center">
                <div className="w-2 h-2 bg-blue-500 rounded-full mr-3 animate-pulse"></div>
                Connection Details
              </h4>
              <div className="space-y-4">
                <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                  <span className="font-medium text-slate-600">Status</span>
                  <div className="flex items-center space-x-2">
                    <div className={`w-2 h-2 rounded-full ${
                      databaseHealth.database_status === 'connected' ? 'bg-green-400' : 'bg-red-400'
                    }`}></div>
                    <span className="font-bold text-slate-900 capitalize">
                      {databaseHealth.database_status}
                    </span>
                  </div>
                </div>
                
                <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                  <span className="font-medium text-slate-600">Response Time</span>
                  <div className="text-right">
                    <div className={`text-lg font-bold ${
                      databaseHealth.response_time_ms < 100 ? 'text-green-600' :
                      databaseHealth.response_time_ms < 500 ? 'text-yellow-600' : 'text-red-600'
                    }`}>
                      {databaseHealth.response_time_ms}ms
                    </div>
                  </div>
                </div>
                
                <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                  <span className="font-medium text-slate-600">Database Time</span>
                  <span className="font-mono text-sm text-slate-900">
                    {databaseHealth.database_time ? new Date(databaseHealth.database_time).toLocaleString() : 'N/A'}
                  </span>
                </div>
              </div>
            </div>

            {/* Performance indicators card */}
            <div className="bg-gradient-to-br from-white/80 to-green-50/80 backdrop-blur-xl rounded-2xl border border-white/20 shadow-xl p-8">
              <h4 className="text-xl font-bold text-slate-900 mb-6 flex items-center">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-3 animate-pulse"></div>
                Performance Indicators
              </h4>
              <div className="space-y-4">
                <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                  <div className={`w-4 h-4 rounded-full ${
                    databaseHealth.response_time_ms < 100 ? 'bg-green-400' :
                    databaseHealth.response_time_ms < 500 ? 'bg-yellow-400' : 'bg-red-400'
                  }`}></div>
                  <div className="flex-1">
                    <div className="font-medium text-slate-700">Response Time</div>
                    <div className="text-sm text-slate-500">
                      {databaseHealth.response_time_ms < 100 ? 'Excellent' :
                       databaseHealth.response_time_ms < 500 ? 'Good' : 'Needs Attention'}
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-bold text-slate-900">
                      {Math.round((1000 / databaseHealth.response_time_ms) * 100) / 100} req/s
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                  <div className="w-4 h-4 bg-green-400 rounded-full animate-pulse shadow-lg shadow-green-400/50"></div>
                  <span className="font-medium text-slate-700">Real-time Monitoring</span>
                </div>
                
                <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                  <div className="w-4 h-4 bg-blue-400 rounded-full animate-pulse shadow-lg shadow-blue-400/50"></div>
                  <span className="font-medium text-slate-700">Auto-refresh: 10s</span>
                </div>
              </div>
            </div>
          </div>
        </Section>
      )}

      {/* System information with enhanced design */}
      <Section
        title="System Information"
        description="Current system status and operational details with comprehensive monitoring"
      >
        <div className="bg-gradient-to-br from-white/80 to-slate-50/80 backdrop-blur-xl rounded-2xl border border-white/20 shadow-xl p-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* API Information */}
            <div>
              <h4 className="text-xl font-bold text-slate-900 mb-6 flex items-center">
                <div className="w-2 h-2 bg-indigo-500 rounded-full mr-3 animate-pulse"></div>
                API Information
              </h4>
              <div className="space-y-4">
                <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                  <span className="font-medium text-slate-600">Endpoint</span>
                  <span className="font-mono text-sm text-slate-900 bg-slate-100 px-2 py-1 rounded">
                    {process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'}
                  </span>
                </div>
                <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                  <span className="font-medium text-slate-600">Environment</span>
                  <span className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-medium">
                    Development
                  </span>
                </div>
                <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                  <span className="font-medium text-slate-600">Version</span>
                  <span className="font-semibold text-slate-900">v1.0.0</span>
                </div>
              </div>
            </div>
            
            {/* Monitoring Status */}
            <div>
              <h4 className="text-xl font-bold text-slate-900 mb-6 flex items-center">
                <div className="w-2 h-2 bg-purple-500 rounded-full mr-3 animate-pulse"></div>
                Monitoring Status
              </h4>
              <div className="space-y-4">
                <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                  <div className="w-3 h-3 bg-green-400 rounded-full animate-pulse shadow-lg shadow-green-400/50"></div>
                  <span className="font-medium text-slate-700">Health checks active</span>
                </div>
                <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                  <div className="w-3 h-3 bg-blue-400 rounded-full animate-pulse shadow-lg shadow-blue-400/50"></div>
                  <span className="font-medium text-slate-700">Real-time updates enabled</span>
                </div>
                <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                  <div className="w-3 h-3 bg-purple-400 rounded-full animate-pulse shadow-lg shadow-purple-400/50"></div>
                  <span className="font-medium text-slate-700">Performance tracking active</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Section>
    </div>
  );
}