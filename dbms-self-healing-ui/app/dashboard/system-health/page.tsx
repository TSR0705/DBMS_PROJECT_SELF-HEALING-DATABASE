'use client';

import { Section } from '@/components/ui-dbms/Section';
import { StatsCard } from '@/components/ui-dbms/StatsCard';
import { useRealtimeData } from '@/lib/realtime-service';

// Ultra-modern System Health Dashboard with real data
export default function SystemHealth() {
  const { data, loading, refresh } = useRealtimeData();

  if (loading || !data) {
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

  const { systemMetrics } = data;
  const isHealthy = systemMetrics.isConnected;

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
            Real-time system health monitoring and performance metrics with
            intelligent diagnostics
          </p>

          {/* Status indicator */}
          <div className="flex items-center justify-center space-x-3 mt-6">
            <div
              className={`flex items-center space-x-2 backdrop-blur-xl rounded-full px-6 py-3 shadow-lg border ${
                isHealthy
                  ? 'bg-green-50/80 border-green-200/50'
                  : 'bg-red-50/80 border-red-200/50'
              }`}
            >
              <div
                className={`w-3 h-3 rounded-full shadow-lg ${
                  isHealthy
                    ? 'bg-green-400 animate-pulse shadow-green-400/50'
                    : 'bg-red-400 shadow-red-400/50'
                }`}
              ></div>
              <span
                className={`text-sm font-bold ${
                  isHealthy ? 'text-green-700' : 'text-red-700'
                }`}
              >
                {isHealthy ? 'HEALTHY' : 'OFFLINE'}
              </span>
            </div>
            <button
              onClick={refresh}
              className="bg-white/80 backdrop-blur-xl rounded-full px-4 py-2 shadow-lg border border-white/20 text-sm text-blue-600 hover:text-blue-800 transition-colors"
            >
              Refresh
            </button>
          </div>
        </div>
      </div>

      {/* Enhanced health status cards with real data */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatsCard
          title="API Status"
          value={isHealthy ? 'HEALTHY' : 'OFFLINE'}
          subtitle="System availability"
          trend={isHealthy ? 'up' : 'down'}
        />

        <StatsCard
          title="Database"
          value={isHealthy ? 'Connected' : 'Disconnected'}
          subtitle="Connection status"
          trend={isHealthy ? 'up' : 'down'}
        />

        <StatsCard
          title="Last Check"
          value={systemMetrics.lastUpdate.toLocaleTimeString()}
          subtitle="Health monitoring"
          trend="neutral"
        />
      </div>

      {/* Real Database performance metrics */}
      <Section
        title="Database Performance"
        description="Real-time database connectivity and performance metrics"
      >
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Connection details card with real data */}
          <div className="bg-gradient-to-br from-white/80 to-blue-50/80 backdrop-blur-xl rounded-2xl border border-white/20 shadow-xl p-8">
            <h4 className="text-xl font-bold text-slate-900 mb-6 flex items-center">
              <div className={`w-2 h-2 rounded-full mr-3 animate-pulse ${isHealthy ? 'bg-blue-500' : 'bg-red-500'}`}></div>
              Connection Details
            </h4>
            <div className="space-y-4">
              <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                <span className="font-medium text-slate-600">Status</span>
                <div className="flex items-center space-x-2">
                  <div
                    className={`w-2 h-2 rounded-full ${
                      isHealthy ? 'bg-green-400' : 'bg-red-400'
                    }`}
                  ></div>
                  <span className="font-bold text-slate-900 capitalize">
                    {isHealthy ? 'Connected' : 'Disconnected'}
                  </span>
                </div>
              </div>

              <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                <span className="font-medium text-slate-600">Uptime</span>
                <div className="text-right">
                  <div className="text-lg font-bold text-green-600">
                    {systemMetrics.uptime}
                  </div>
                </div>
              </div>

              <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                <span className="font-medium text-slate-600">Detection Time</span>
                <span className="font-mono text-sm text-slate-900">
                  {systemMetrics.detectionTime}
                </span>
              </div>
            </div>
          </div>

          {/* Performance indicators card with real data */}
          <div className="bg-gradient-to-br from-white/80 to-green-50/80 backdrop-blur-xl rounded-2xl border border-white/20 shadow-xl p-8">
            <h4 className="text-xl font-bold text-slate-900 mb-6 flex items-center">
              <div className={`w-2 h-2 rounded-full mr-3 animate-pulse ${isHealthy ? 'bg-green-500' : 'bg-red-500'}`}></div>
              Performance Indicators
            </h4>
            <div className="space-y-4">
              <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                <div className={`w-4 h-4 rounded-full ${isHealthy ? 'bg-green-400' : 'bg-red-400'}`}></div>
                <div className="flex-1">
                  <div className="font-medium text-slate-700">Auto-Heal Success</div>
                  <div className="text-sm text-slate-500">
                    {systemMetrics.autoHealSuccessRate}% success rate
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-bold text-slate-900">
                    {systemMetrics.autoHealSuccessRate}%
                  </div>
                </div>
              </div>

              <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                <div className={`w-4 h-4 rounded-full animate-pulse ${isHealthy ? 'bg-green-400 shadow-lg shadow-green-400/50' : 'bg-red-400'}`}></div>
                <span className="font-medium text-slate-700">
                  {isHealthy ? 'Real-time Monitoring' : 'Monitoring Offline'}
                </span>
              </div>

              <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                <div className="w-4 h-4 bg-blue-400 rounded-full animate-pulse shadow-lg shadow-blue-400/50"></div>
                <span className="font-medium text-slate-700">
                  Auto-refresh: 30s
                </span>
              </div>
            </div>
          </div>
        </div>
      </Section>

      {/* Real System information */}
      <Section
        title="System Information"
        description="Current system status and operational details with real metrics"
      >
        <div className="bg-gradient-to-br from-white/80 to-slate-50/80 backdrop-blur-xl rounded-2xl border border-white/20 shadow-xl p-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Real System Metrics */}
            <div>
              <h4 className="text-xl font-bold text-slate-900 mb-6 flex items-center">
                <div className="w-2 h-2 bg-indigo-500 rounded-full mr-3 animate-pulse"></div>
                System Metrics
              </h4>
              <div className="space-y-4">
                <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                  <span className="font-medium text-slate-600">Total Issues</span>
                  <span className="font-bold text-slate-900">{systemMetrics.totalIssues}</span>
                </div>
                <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                  <span className="font-medium text-slate-600">Actions Taken</span>
                  <span className="font-bold text-slate-900">{systemMetrics.totalActions}</span>
                </div>
                <div className="flex justify-between items-center p-4 bg-white/60 rounded-xl border border-white/30">
                  <span className="font-medium text-slate-600">Issues Resolved</span>
                  <span className="font-bold text-slate-900">{systemMetrics.issuesResolved}</span>
                </div>
              </div>
            </div>

            {/* Real Monitoring Status */}
            <div>
              <h4 className="text-xl font-bold text-slate-900 mb-6 flex items-center">
                <div className="w-2 h-2 bg-purple-500 rounded-full mr-3 animate-pulse"></div>
                Monitoring Status
              </h4>
              <div className="space-y-4">
                <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                  <div className={`w-3 h-3 rounded-full animate-pulse ${isHealthy ? 'bg-green-400 shadow-lg shadow-green-400/50' : 'bg-red-400'}`}></div>
                  <span className="font-medium text-slate-700">
                    {isHealthy ? 'Health checks active' : 'Health checks offline'}
                  </span>
                </div>
                <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                  <div className={`w-3 h-3 rounded-full animate-pulse ${isHealthy ? 'bg-blue-400 shadow-lg shadow-blue-400/50' : 'bg-gray-400'}`}></div>
                  <span className="font-medium text-slate-700">
                    {isHealthy ? 'Real-time updates enabled' : 'Updates disabled'}
                  </span>
                </div>
                <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                  <div className={`w-3 h-3 rounded-full animate-pulse ${isHealthy ? 'bg-purple-400 shadow-lg shadow-purple-400/50' : 'bg-gray-400'}`}></div>
                  <span className="font-medium text-slate-700">
                    {isHealthy ? 'Performance tracking active' : 'Tracking offline'}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Section>

      {/* Real-time Statistics Summary */}
      <Section
        title="Real-time Statistics"
        description="Live system performance and health metrics"
      >
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          <div className="text-center p-6 bg-white border border-slate-200 rounded-xl">
            <div className="text-3xl font-bold text-slate-900 mb-2">{systemMetrics.totalAnalysis}</div>
            <div className="text-slate-600 text-sm">AI Analysis</div>
          </div>
          <div className="text-center p-6 bg-white border border-slate-200 rounded-xl">
            <div className="text-3xl font-bold text-slate-900 mb-2">{systemMetrics.totalDecisions}</div>
            <div className="text-slate-600 text-sm">Decisions</div>
          </div>
          <div className="text-center p-6 bg-white border border-slate-200 rounded-xl">
            <div className="text-3xl font-bold text-slate-900 mb-2">{systemMetrics.totalLearning}</div>
            <div className="text-slate-600 text-sm">Learning Records</div>
          </div>
          <div className="text-center p-6 bg-white border border-slate-200 rounded-xl">
            <div className="text-3xl font-bold text-slate-900 mb-2">{systemMetrics.totalReviews}</div>
            <div className="text-slate-600 text-sm">Admin Reviews</div>
          </div>
        </div>
      </Section>
    </div>
  );
}
