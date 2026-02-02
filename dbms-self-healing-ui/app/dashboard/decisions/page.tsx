'use client';

import { useEffect, useState } from 'react';
import { DataTable, DataTableColumn } from '@/components/ui-dbms/DataTable';
import { Section } from '@/components/ui-dbms/Section';
import { StatsCard } from '@/components/ui-dbms/StatsCard';
import { StatusBadge } from '@/components/ui-dbms/StatusBadge';
import { apiClient, DecisionLog } from '@/lib/api';

export default function DecisionsPage() {
  const [decisions, setDecisions] = useState<DecisionLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalDecisions: 0,
    autoHeal: 0,
    adminReview: 0,
    avgConfidence: 0,
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const decisionData = await apiClient.getAllDecisions();
        setDecisions(decisionData);

        // Calculate stats
        const autoHealCount = decisionData.filter(
          d => d.decision_type === 'AUTO_HEAL'
        ).length;
        const adminReviewCount = decisionData.filter(
          d => d.decision_type === 'ADMIN_REVIEW'
        ).length;
        const avgConf =
          decisionData.length > 0
            ? decisionData.reduce(
                (sum, d) => sum + d.confidence_at_decision,
                0
              ) / decisionData.length
            : 0;

        setStats({
          totalDecisions: decisionData.length,
          autoHeal: autoHealCount,
          adminReview: adminReviewCount,
          avgConfidence: Math.round(avgConf * 100),
        });
      } catch (error) {
        console.error('Error fetching decision data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

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
        return <StatusBadge status={value} variant={variant} />;
      },
    },
    {
      key: 'decision_reason',
      header: 'Reason',
      render: value => (
        <div className="max-w-xs">
          <p className="text-sm text-slate-700 truncate" title={value}>
            {value}
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
              style={{ width: `${value * 100}%` }}
            />
          </div>
          <span className="text-sm font-medium">
            {Math.round(value * 100)}%
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
        <h1 className="text-3xl font-bold text-slate-900 mb-2">Decision Log</h1>
        <p className="text-slate-600">
          Automated and manual decisions made for detected database issues
        </p>
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
        <DataTable columns={columns} data={decisions} loading={loading} />
      </Section>

      {/* Decision Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Section
          title="Decision Types"
          description="Distribution of decision types"
        >
          <div className="space-y-4">
            {['AUTO_HEAL', 'ADMIN_REVIEW', 'ESCALATED'].map(decisionType => {
              const count = decisions.filter(
                d => d.decision_type === decisionType
              ).length;
              const percentage =
                decisions.length > 0 ? (count / decisions.length) * 100 : 0;

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
            {decisions.slice(0, 5).map(decision => (
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
