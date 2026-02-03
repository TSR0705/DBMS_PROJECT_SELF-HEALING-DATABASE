'use client';

import { StatsCard } from '@/components/ui-dbms/StatsCard';
import { Section } from '@/components/ui-dbms/Section';
import { useRealtimeData } from '@/lib/realtime-service';

export default function SystemOverview() {
  const { data, loading, refresh } = useRealtimeData();

  if (loading || !data) {
    return (
      <div className="space-y-8">
        <div className="animate-pulse space-y-6">
          <div className="h-20 bg-slate-200 rounded"></div>
          <div className="h-8 bg-slate-200 rounded w-2/3"></div>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="h-40 bg-slate-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  const { systemMetrics, recentIssues, recentActions } = data;

  return (
    <div className="space-y-8">
      {/* Header with real system status */}
      <div className="border-b border-slate-200 pb-6">
        <h1 className="text-3xl font-bold text-slate-900 mb-2">
          System Overview
        </h1>
        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-2">
            <div
              className={`w-3 h-3 rounded-full ${systemMetrics.isConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`}
            ></div>
            <span className="text-sm text-slate-600">
              Database:{' '}
              {systemMetrics.isConnected ? 'Connected' : 'Disconnected'}
            </span>
          </div>
          <div className="text-sm text-slate-500">
            Last updated: {systemMetrics.lastUpdate.toLocaleTimeString()}
          </div>
          <button
            onClick={refresh}
            className="text-sm text-blue-600 hover:text-blue-800 transition-colors"
          >
            Refresh
          </button>
        </div>
      </div>

      {/* Real Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-6">
        <StatsCard
          title="Issues Detected"
          value={systemMetrics.totalIssues}
          subtitle="Total database issues"
          trend={systemMetrics.totalIssues > 0 ? 'up' : 'neutral'}
        />

        <StatsCard
          title="AI Analysis"
          value={systemMetrics.totalAnalysis}
          subtitle="Completed analysis"
          trend="neutral"
        />

        <StatsCard
          title="Decisions Made"
          value={systemMetrics.totalDecisions}
          subtitle="System decisions"
          trend="neutral"
        />

        <StatsCard
          title="Actions Taken"
          value={systemMetrics.totalActions}
          subtitle="Healing actions"
          trend="neutral"
        />

        <StatsCard
          title="Admin Reviews"
          value={systemMetrics.totalReviews}
          subtitle="Manual reviews"
          trend="neutral"
        />

        <StatsCard
          title="Learning Records"
          value={systemMetrics.totalLearning}
          subtitle="System learning"
          trend="neutral"
        />
      </div>

      {/* Real Recent Issues */}
      <Section
        title="Recent Issues"
        description="Latest detected database issues from monitoring systems"
      >
        {recentIssues.length > 0 ? (
          <div className="space-y-4">
            {recentIssues.map(issue => (
              <div
                key={issue.issue_id}
                className="bg-white border border-slate-200 p-4 rounded"
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-3">
                    <span className="font-mono text-sm bg-slate-100 px-2 py-1 rounded">
                      #{issue.issue_id}
                    </span>
                    <span className="font-semibold text-slate-900">
                      {issue.issue_type}
                    </span>
                  </div>
                  <span className="text-sm text-slate-500">
                    {new Date(issue.detected_at).toLocaleString()}
                  </span>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                  <div>
                    <span className="text-slate-600">Source:</span>
                    <p className="font-medium">{issue.detection_source}</p>
                  </div>
                  <div>
                    <span className="text-slate-600">Metric Value:</span>
                    <p className="font-medium">
                      {issue.raw_metric_value} {issue.raw_metric_unit}
                    </p>
                  </div>
                  <div>
                    <span className="text-slate-600">Detected:</span>
                    <p className="font-medium">
                      {new Date(issue.detected_at).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-slate-500">
            No issues detected in the system
          </div>
        )}
      </Section>

      {/* Real Recent Actions */}
      <Section
        title="Recent Actions"
        description="Latest healing actions executed by the system"
      >
        {recentActions.length > 0 ? (
          <div className="space-y-4">
            {recentActions.map(action => (
              <div
                key={action.action_id}
                className="bg-white border border-slate-200 p-4 rounded"
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-3">
                    <span className="font-mono text-sm bg-slate-100 px-2 py-1 rounded">
                      #{action.action_id}
                    </span>
                    <span className="font-semibold text-slate-900">
                      {action.action_type}
                    </span>
                    <span
                      className={`px-2 py-1 rounded text-xs font-medium ${
                        action.execution_status === 'SUCCESS'
                          ? 'bg-green-100 text-green-700'
                          : action.execution_status === 'FAILED'
                            ? 'bg-red-100 text-red-700'
                            : 'bg-yellow-100 text-yellow-700'
                      }`}
                    >
                      {action.execution_status}
                    </span>
                  </div>
                  <span className="text-sm text-slate-500">
                    {new Date(action.executed_at).toLocaleString()}
                  </span>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                  <div>
                    <span className="text-slate-600">Mode:</span>
                    <p className="font-medium">{action.execution_mode}</p>
                  </div>
                  <div>
                    <span className="text-slate-600">Executed By:</span>
                    <p className="font-medium">{action.executed_by}</p>
                  </div>
                  <div>
                    <span className="text-slate-600">Decision ID:</span>
                    <p className="font-medium">#{action.decision_id}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-8 text-slate-500">
            No healing actions have been executed yet
          </div>
        )}
      </Section>

      {/* System Health Summary */}
      <Section
        title="System Health Summary"
        description="Current status of all DBMS monitoring components"
      >
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white border border-slate-200 p-6 rounded">
            <h3 className="font-semibold text-slate-900 mb-4">
              Database Status
            </h3>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-slate-600">Connection</span>
                <span
                  className={`font-medium ${systemMetrics.isConnected ? 'text-green-600' : 'text-red-600'}`}
                >
                  {systemMetrics.isConnected ? 'Connected' : 'Disconnected'}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-600">Total Issues</span>
                <span className="font-medium">{systemMetrics.totalIssues}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-600">Actions Executed</span>
                <span className="font-medium">
                  {systemMetrics.totalActions}
                </span>
              </div>
            </div>
          </div>

          <div className="bg-white border border-slate-200 p-6 rounded">
            <h3 className="font-semibold text-slate-900 mb-4">AI Processing</h3>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-slate-600">Analysis Completed</span>
                <span className="font-medium">
                  {systemMetrics.totalAnalysis}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-600">Decisions Made</span>
                <span className="font-medium">
                  {systemMetrics.totalDecisions}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-600">Learning Records</span>
                <span className="font-medium">
                  {systemMetrics.totalLearning}
                </span>
              </div>
            </div>
          </div>
        </div>
      </Section>
    </div>
  );
}
