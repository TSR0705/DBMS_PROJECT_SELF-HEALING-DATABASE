'use client';

import { DataTable, DataTableColumn } from '@/components/ui-dbms/DataTable';
import { Section } from '@/components/ui-dbms/Section';
import { StatsCard } from '@/components/ui-dbms/StatsCard';
import { StatusBadge } from '@/components/ui-dbms/StatusBadge';
import { useRealtimeData } from '@/lib/realtime-service';
import type { DecisionLog } from '@/lib/api';

export default function DecisionsPage() {
  const { data, loading, refresh } = useRealtimeData();

  if (loading || !data) {
    return (
      <div className="space-y-8">
        <div className="animate-pulse space-y-6">
          <div className="h-20 bg-slate-200 rounded"></div>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="h-40 bg-slate-200 rounded"></div>
            ))}
          </div>
          <div className="h-96 bg-slate-200 rounded"></div>
        </div>
      </div>
    );
  }

  const { recentDecisions, systemMetrics } = data;

  // Calculate real stats from data
  const autoHealCount = recentDecisions.filter(
    d => d.decision_type === 'AUTO_HEAL'
  ).length;
  const adminReviewCount = recentDecisions.filter(
    d => d.decision_type === 'ADMIN_REVIEW'
  ).length;
  const avgConf =
    recentDecisions.length > 0
      ? recentDecisions.reduce((sum, d) => sum + d.confidence_at_decision, 0) /
        recentDecisions.length
      : 0;

  const stats = {
    totalDecisions: recentDecisions.length,
    autoHeal: autoHealCount,
    adminReview: adminReviewCount,
    avgConfidence: Math.round(avgConf * 100),
  };

  const columns: DataTableColumn<DecisionLog>[] = [
    {
      key: 'decision_id',
      header: 'Decision ID',
      render: value => (
        <span className="font-mono text-sm bg-slate-100 px-2 py-1 rounded">
          #{value}
        </span>
      ),
    },
    {
      key: 'issue_id',
      header: 'Issue ID',
      render: value => (
        <span className="font-mono text-sm text-blue-600">#{value}</span>
      ),
    },
    {
      key: 'decision_type',
      header: 'Decision Type',
      render: value => {
        const variant =
          value === 'AUTO_HEAL'
            ? 'success'
            : value === 'ADMIN_REVIEW'
              ? 'warning'
              : 'default';
        return <StatusBadge status={String(value)} variant={variant} />;
      },
    },
    {
      key: 'decision_reason',
      header: 'Reason',
      render: value => (
        <div className="max-w-xs">
          <p className="text-sm text-slate-700 truncate" title={String(value)}>
            {String(value)}
          </p>
        </div>
      ),
    },
    {
      key: 'confidence_at_decision',
      header: 'Confidence',
      render: value => (
        <div className="flex items-center space-x-2">
          <div className="w-16 bg-slate-200 rounded-full h-2">
            <div
              className="bg-blue-500 h-2 rounded-full"
              style={{
                width: `${typeof value === 'number' ? value * 100 : 0}%`,
              }}
            />
          </div>
          <span className="text-sm font-medium">
            {typeof value === 'number' ? Math.round(value * 100) : 0}%
          </span>
        </div>
      ),
    },
    {
      key: 'decided_at',
      header: 'Decided At',
      render: value => (
        <span className="text-sm text-slate-500">
          {new Date(value).toLocaleString()}
        </span>
      ),
    },
  ];

  return (
    <div className="space-y-8">
      {/* Page Header */}
      <div className="border-b border-slate-200 pb-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 mb-2">
              Decision Log
            </h1>
            <p className="text-slate-600">
              Automated and manual decisions made for detected database issues
            </p>
          </div>
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <div
                className={`w-3 h-3 rounded-full ${systemMetrics.isConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`}
              ></div>
              <span className="text-sm text-slate-600">
                {systemMetrics.isConnected ? 'Live Data' : 'Offline'}
              </span>
            </div>
            <button
              onClick={refresh}
              className="text-sm text-blue-600 hover:text-blue-800 transition-colors"
            >
              Refresh
            </button>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <StatsCard
          title="Total Decisions"
          value={stats.totalDecisions}
          subtitle="Decisions made"
          trend="neutral"
        />
        <StatsCard
          title="Auto Heal"
          value={stats.autoHeal}
          subtitle="Automated decisions"
          trend={stats.autoHeal > 0 ? 'up' : 'neutral'}
        />
        <StatsCard
          title="Admin Review"
          value={stats.adminReview}
          subtitle="Manual review required"
          trend={stats.adminReview > 0 ? 'up' : 'neutral'}
        />
        <StatsCard
          title="Avg Confidence"
          value={`${stats.avgConfidence}%`}
          subtitle="Decision confidence"
          trend={stats.avgConfidence > 70 ? 'up' : 'neutral'}
        />
      </div>

      {/* Decision Log Table */}
      <Section
        title="Decision History"
        description="Complete log of all decisions made by the system"
      >
        <DataTable columns={columns} data={recentDecisions} loading={loading} />
      </Section>

      {/* Decision Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Section
          title="Decision Types"
          description="Distribution of decision types"
        >
          <div className="space-y-4">
            {['AUTO_HEAL', 'ADMIN_REVIEW', 'ESCALATED'].map(decisionType => {
              const count = recentDecisions.filter(
                d => d.decision_type === decisionType
              ).length;
              const percentage =
                recentDecisions.length > 0
                  ? (count / recentDecisions.length) * 100
                  : 0;

              return (
                <div
                  key={decisionType}
                  className="flex items-center justify-between p-4 bg-slate-50 rounded-xl"
                >
                  <div className="flex items-center space-x-3">
                    <StatusBadge
                      status={decisionType}
                      variant={
                        decisionType === 'AUTO_HEAL'
                          ? 'success'
                          : decisionType === 'ADMIN_REVIEW'
                            ? 'warning'
                            : 'default'
                      }
                    />
                    <span className="font-medium">{count} decisions</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="w-20 bg-slate-200 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full ${
                          decisionType === 'AUTO_HEAL'
                            ? 'bg-green-500'
                            : decisionType === 'ADMIN_REVIEW'
                              ? 'bg-yellow-500'
                              : 'bg-slate-500'
                        }`}
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                    <span className="text-sm text-slate-600">
                      {Math.round(percentage)}%
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        </Section>

        <Section
          title="Recent Decisions"
          description="Latest decision-making activity"
        >
          <div className="space-y-4">
            {recentDecisions.slice(0, 5).map(decision => (
              <div
                key={decision.decision_id}
                className="p-4 bg-white border border-slate-200 rounded-xl"
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <span className="font-mono text-sm text-slate-500">
                      #{decision.decision_id}
                    </span>
                    <StatusBadge
                      status={decision.decision_type}
                      variant={
                        decision.decision_type === 'AUTO_HEAL'
                          ? 'success'
                          : 'warning'
                      }
                    />
                  </div>
                  <span className="text-xs text-slate-500">
                    {new Date(decision.decided_at).toLocaleString()}
                  </span>
                </div>
                <p className="text-sm text-slate-700 mb-2">
                  {decision.decision_reason}
                </p>
                <div className="flex items-center space-x-2">
                  <span className="text-xs text-slate-600">Confidence:</span>
                  <div className="w-16 bg-slate-200 rounded-full h-1.5">
                    <div
                      className="bg-blue-500 h-1.5 rounded-full"
                      style={{
                        width: `${decision.confidence_at_decision * 100}%`,
                      }}
                    />
                  </div>
                  <span className="text-xs font-medium">
                    {Math.round(decision.confidence_at_decision * 100)}%
                  </span>
                </div>
              </div>
            ))}
          </div>
        </Section>
      </div>
    </div>
  );
}
