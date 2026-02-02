'use client';

import { useEffect, useState } from 'react';
import { DataTable, DataTableColumn } from '@/components/ui-dbms/DataTable';
import { Section } from '@/components/ui-dbms/Section';
import { StatsCard } from '@/components/ui-dbms/StatsCard';
import { Badge } from '@/components/ui/badge';
import { apiClient, DetectedIssue } from '@/lib/api';

// Enhanced column definitions for real API data with modern styling
const issueColumns: DataTableColumn<DetectedIssue>[] = [
  {
    key: 'issue_id',
    header: 'Issue ID',
    className: 'font-mono text-xs text-slate-600 font-medium',
    render: value => (
      <div className="flex items-center space-x-2">
        <div className="w-2 h-2 bg-blue-400 rounded-full animate-pulse"></div>
        <span className="bg-slate-100 px-2 py-1 rounded-md text-xs font-mono">
          #{value}
        </span>
      </div>
    ),
  },
  {
    key: 'issue_type',
    header: 'Issue Type',
    className: 'font-semibold text-slate-900',
    render: value => (
      <div className="flex items-center space-x-2">
        <div
          className={`w-3 h-3 rounded-full ${
            value === 'SLOW_QUERY'
              ? 'bg-yellow-400'
              : value === 'DEADLOCK'
                ? 'bg-red-400'
                : 'bg-blue-400'
          }`}
        ></div>
        <span className="font-semibold">{value.replace('_', ' ')}</span>
      </div>
    ),
  },
  {
    key: 'detection_source',
    header: 'Detection Source',
    className: 'text-slate-700',
    render: value => (
      <Badge
        variant="secondary"
        className="bg-blue-50 text-blue-700 border-blue-200"
      >
        {value}
      </Badge>
    ),
  },
  {
    key: 'raw_metric_value',
    header: 'Metric Value',
    className: 'font-mono text-xs text-slate-600',
    render: value => (
      <div className="text-right">
        <span className="bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent font-bold">
          {value !== null ? Number(value).toFixed(2) : 'N/A'}
        </span>
      </div>
    ),
  },
  {
    key: 'detected_at',
    header: 'Detection Time',
    className: 'font-mono text-xs text-slate-600',
    render: value => (
      <div className="text-right">
        <div className="text-xs font-medium text-slate-900">
          {new Date(value).toLocaleDateString()}
        </div>
        <div className="text-xs text-slate-500">
          {new Date(value).toLocaleTimeString()}
        </div>
      </div>
    ),
  },
];

// Ultra-modern Issues Dashboard with stunning visual design
export default function DetectedIssues() {
  const [issues, setIssues] = useState<DetectedIssue[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchIssues = async () => {
      try {
        setLoading(true);
        const data = await apiClient.getDetectedIssues();
        setIssues(data);
        setError(null);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch issues');
        console.error('Error fetching issues:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchIssues();

    // Set up polling for real-time updates every 30 seconds
    const interval = setInterval(fetchIssues, 30000);

    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        {/* Loading skeleton with shimmer effect */}
        <div className="space-y-6">
          <div className="shimmer h-12 rounded-2xl"></div>
          <div className="shimmer h-6 rounded-xl w-2/3"></div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="shimmer h-32 rounded-2xl"></div>
            ))}
          </div>
          <div className="shimmer h-96 rounded-2xl"></div>
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
            Detected Issues
          </h1>
          <p className="text-lg text-slate-600 max-w-2xl mx-auto">
            Real-time monitoring and anomaly detection across database systems
          </p>
        </div>

        {/* Enhanced error state */}
        <div className="max-w-2xl mx-auto">
          <div className="bg-gradient-to-br from-red-50 to-rose-50 border border-red-200 rounded-2xl p-8 shadow-lg">
            <div className="flex items-center space-x-4">
              <div className="w-12 h-12 bg-red-500 rounded-2xl flex items-center justify-center shadow-lg">
                <svg
                  className="w-6 h-6 text-white"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
                  />
                </svg>
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold text-red-900 mb-2">
                  Connection Error
                </h3>
                <p className="text-red-700 mb-3">{error}</p>
                <p className="text-red-600 text-sm">
                  Make sure the backend server is running on
                  http://localhost:8000
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Get unique detection sources for stats
  const detectionSources = Array.from(
    new Set(issues.map(i => i.detection_source))
  );
  const issueTypes = Array.from(new Set(issues.map(i => i.issue_type)));

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Ultra-modern header with gradient text */}
      <div className="text-center space-y-6 relative">
        <div className="absolute inset-0 bg-gradient-to-r from-blue-600/10 via-purple-600/10 to-indigo-600/10 rounded-3xl blur-3xl"></div>
        <div className="relative z-10 py-8">
          <h1 className="text-5xl font-black bg-gradient-to-r from-slate-900 via-blue-900 to-indigo-900 bg-clip-text text-transparent mb-4">
            Detected Issues
          </h1>
          <p className="text-xl text-slate-600 max-w-3xl mx-auto leading-relaxed">
            Real-time monitoring and anomaly detection across database systems
            with AI-powered analysis
          </p>

          {/* Live indicator */}
          <div className="flex items-center justify-center space-x-3 mt-6">
            <div className="flex items-center space-x-2 bg-white/80 backdrop-blur-xl rounded-full px-4 py-2 shadow-lg border border-white/20">
              <div className="w-3 h-3 bg-green-400 rounded-full animate-pulse shadow-lg shadow-green-400/50"></div>
              <span className="text-sm font-semibold text-slate-700">
                Live Data
              </span>
            </div>
            <div className="bg-white/80 backdrop-blur-xl rounded-full px-4 py-2 shadow-lg border border-white/20">
              <span className="text-sm font-mono text-slate-700">
                {issues.length} Issues Detected
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Enhanced stats grid with modern cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatsCard
          title="Total Issues"
          value={issues.length}
          subtitle="Active monitoring"
          color="blue"
          icon={
            <svg
              className="w-5 h-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              />
            </svg>
          }
        />

        <StatsCard
          title="Detection Sources"
          value={detectionSources.length}
          subtitle="Active monitors"
          color="green"
          icon={
            <svg
              className="w-5 h-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
              />
            </svg>
          }
        />

        <StatsCard
          title="Last Detection"
          value={
            issues.length > 0
              ? new Date(
                  Math.max(
                    ...issues.map(i => new Date(i.detected_at).getTime())
                  )
                ).toLocaleTimeString()
              : 'N/A'
          }
          subtitle="Most recent"
          color="purple"
          icon={
            <svg
              className="w-5 h-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          }
        />
      </div>

      {/* Main issues table with enhanced styling */}
      <Section
        title="Active Monitoring Feed"
        description="Live stream of detected anomalies, performance issues, and system alerts from database monitoring agents."
      >
        {issues.length > 0 ? (
          <div className="bg-white/50 backdrop-blur-xl rounded-2xl border border-white/20 shadow-xl overflow-hidden">
            <DataTable columns={issueColumns} data={issues} />
          </div>
        ) : (
          <div className="bg-gradient-to-br from-slate-50 to-blue-50 border border-slate-200 rounded-2xl p-12 text-center shadow-lg">
            <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg">
              <svg
                className="w-8 h-8 text-white"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div className="text-slate-600">
              <div className="text-xl font-bold mb-2">No Issues Detected</div>
              <div className="text-sm">
                The system is currently running without detected issues.
              </div>
            </div>
          </div>
        )}
      </Section>

      {/* Enhanced insights grid */}
      {detectionSources.length > 0 && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Detection sources breakdown */}
          <div className="bg-gradient-to-br from-white/80 to-blue-50/80 backdrop-blur-xl rounded-2xl border border-white/20 shadow-xl p-8">
            <h3 className="text-xl font-bold text-slate-900 mb-6 flex items-center">
              <div className="w-2 h-2 bg-blue-500 rounded-full mr-3 animate-pulse"></div>
              Detection Sources
            </h3>
            <div className="space-y-4">
              {detectionSources.map(source => (
                <div
                  key={source}
                  className="flex items-center justify-between p-4 bg-white/60 rounded-xl border border-white/30"
                >
                  <div className="flex items-center space-x-3">
                    <div className="w-3 h-3 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-full"></div>
                    <span className="font-medium text-slate-700">{source}</span>
                  </div>
                  <div className="bg-gradient-to-r from-blue-500 to-indigo-600 text-white px-3 py-1 rounded-full text-sm font-bold">
                    {issues.filter(i => i.detection_source === source).length}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* System status */}
          <div className="bg-gradient-to-br from-white/80 to-green-50/80 backdrop-blur-xl rounded-2xl border border-white/20 shadow-xl p-8">
            <h3 className="text-xl font-bold text-slate-900 mb-6 flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full mr-3 animate-pulse"></div>
              System Status
            </h3>
            <div className="space-y-4">
              <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                <div className="w-3 h-3 bg-green-400 rounded-full animate-pulse shadow-lg shadow-green-400/50"></div>
                <span className="font-medium text-slate-700">
                  API Connected
                </span>
              </div>
              <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                <div className="w-3 h-3 bg-blue-400 rounded-full animate-pulse shadow-lg shadow-blue-400/50"></div>
                <span className="font-medium text-slate-700">
                  Real-time Monitoring
                </span>
              </div>
              <div className="flex items-center space-x-3 p-4 bg-white/60 rounded-xl border border-white/30">
                <div className="w-3 h-3 bg-purple-400 rounded-full animate-pulse shadow-lg shadow-purple-400/50"></div>
                <span className="font-medium text-slate-700">
                  Auto-refresh: 30s
                </span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
