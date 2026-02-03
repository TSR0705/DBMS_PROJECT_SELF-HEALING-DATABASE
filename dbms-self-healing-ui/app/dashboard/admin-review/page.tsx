'use client';

import { DataTable, DataTableColumn } from '@/components/ui-dbms/DataTable';
import { Section } from '@/components/ui-dbms/Section';
import { StatsCard } from '@/components/ui-dbms/StatsCard';
import { StatusBadge } from '@/components/ui-dbms/StatusBadge';
import { useRealtimeData } from '@/lib/realtime-service';
import { AdminReview } from '@/lib/api';

export default function AdminReviewPage() {
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

  const { recentReviews, systemMetrics } = data;

  // Calculate real stats from data
  const approvedCount = recentReviews.filter(
    r => r.admin_action === 'APPROVED'
  ).length;
  const rejectedCount = recentReviews.filter(
    r => r.admin_action === 'REJECTED'
  ).length;
  const overriddenCount = recentReviews.filter(
    r => r.override_flag === true
  ).length;

  const stats = {
    totalReviews: recentReviews.length,
    approved: approvedCount,
    rejected: rejectedCount,
    overridden: overriddenCount,
  };

  const columns: DataTableColumn<AdminReview>[] = [
    {
      key: 'review_id',
      header: 'Review ID',
      render: value => (
        <span className="font-mono text-sm bg-slate-100 px-2 py-1 rounded">
          #{value}
        </span>
      ),
    },
    {
      key: 'decision_id',
      header: 'Decision ID',
      render: value => (
        <span className="font-mono text-sm text-purple-600">#{value}</span>
      ),
    },
    {
      key: 'admin_action',
      header: 'Admin Action',
      render: value => {
        const variant =
          value === 'APPROVED'
            ? 'success'
            : value === 'REJECTED'
              ? 'error'
              : 'warning';
        return <StatusBadge status={value} variant={variant} />;
      },
    },
    {
      key: 'admin_comment',
      header: 'Comment',
      render: value => (
        <div className="max-w-xs">
          <p className="text-sm text-slate-700 truncate" title={value || 'No comment'}>
            {value || 'No comment provided'}
          </p>
        </div>
      ),
    },
    {
      key: 'override_flag',
      header: 'Override',
      render: value => (
        <span
          className={`text-xs px-2 py-1 rounded-full ${
            value
              ? 'bg-red-100 text-red-700'
              : 'bg-green-100 text-green-700'
          }`}
        >
          {value ? 'YES' : 'NO'}
        </span>
      ),
    },
    {
      key: 'reviewed_at',
      header: 'Reviewed At',
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
            <h1 className="text-3xl font-bold text-slate-900 mb-2">Admin Review</h1>
            <p className="text-slate-600">
              Human validation and intervention points for critical system decisions
            </p>
          </div>
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <div className={`w-3 h-3 rounded-full ${systemMetrics.isConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`}></div>
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
          title="Total Reviews"
          value={stats.totalReviews}
          subtitle="Admin interventions"
          trend="neutral"
        />
        <StatsCard
          title="Approved"
          value={stats.approved}
          subtitle="Decisions approved"
          trend={stats.approved > 0 ? 'up' : 'neutral'}
        />
        <StatsCard
          title="Rejected"
          value={stats.rejected}
          subtitle="Decisions rejected"
          trend={stats.rejected > 0 ? 'down' : 'neutral'}
        />
        <StatsCard
          title="Overridden"
          value={stats.overridden}
          subtitle="System overrides"
          trend={stats.overridden > 0 ? 'up' : 'neutral'}
        />
      </div>

      {/* Admin Reviews Table */}
      <Section
        title="Review History"
        description="Complete log of administrative reviews and interventions"
      >
        {recentReviews.length > 0 ? (
          <DataTable columns={columns} data={recentReviews} loading={loading} />
        ) : (
          <div className="text-center py-12 bg-slate-50 rounded-xl">
            <div className="w-16 h-16 bg-slate-200 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg
                className="w-8 h-8 text-slate-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-slate-900 mb-2">
              No Admin Reviews
            </h3>
            <p className="text-slate-600">
              No administrative reviews have been recorded yet
            </p>
          </div>
        )}
      </Section>

      {/* Review Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Section
          title="Review Actions"
          description="Distribution of administrative actions"
        >
          <div className="space-y-4">
            {['APPROVED', 'REJECTED', 'ESCALATED'].map(action => {
              const count = recentReviews.filter(
                r => r.admin_action === action
              ).length;
              const percentage =
                recentReviews.length > 0 ? (count / recentReviews.length) * 100 : 0;

              return (
                <div
                  key={action}
                  className="flex items-center justify-between p-4 bg-slate-50 rounded-xl"
                >
                  <div className="flex items-center space-x-3">
                    <StatusBadge
                      status={action}
                      variant={
                        action === 'APPROVED'
                          ? 'success'
                          : action === 'REJECTED'
                            ? 'error'
                            : 'warning'
                      }
                    />
                    <span className="font-medium">{count} reviews</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="w-20 bg-slate-200 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full ${
                          action === 'APPROVED'
                            ? 'bg-green-500'
                            : action === 'REJECTED'
                              ? 'bg-red-500'
                              : 'bg-yellow-500'
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
          title="Recent Reviews"
          description="Latest administrative interventions"
        >
          <div className="space-y-4">
            {recentReviews.slice(0, 5).map(review => (
              <div
                key={review.review_id}
                className="p-4 bg-white border border-slate-200 rounded-xl"
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <span className="font-mono text-sm text-slate-500">
                      #{review.review_id}
                    </span>
                    <StatusBadge
                      status={review.admin_action}
                      variant={
                        review.admin_action === 'APPROVED'
                          ? 'success'
                          : review.admin_action === 'REJECTED'
                            ? 'error'
                            : 'warning'
                      }
                    />
                    {review.override_flag && (
                      <span className="text-xs bg-red-100 text-red-700 px-2 py-1 rounded-full">
                        OVERRIDE
                      </span>
                    )}
                  </div>
                  <span className="text-xs text-slate-500">
                    {new Date(review.reviewed_at).toLocaleString()}
                  </span>
                </div>
                <p className="text-sm text-slate-700 mb-2">
                  {review.admin_comment || 'No comment provided'}
                </p>
                <div className="text-xs text-slate-500">
                  Decision ID: #{review.decision_id}
                </div>
              </div>
            ))}
          </div>
        </Section>
      </div>

      {/* Admin Guidelines */}
      <Section
        title="Review Guidelines"
        description="Administrative review process and best practices"
      >
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="p-6 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl">
            <h4 className="font-semibold text-slate-900 mb-2">
              Approval Criteria
            </h4>
            <ul className="text-sm text-slate-600 space-y-1">
              <li>• Low risk to system stability</li>
              <li>• Well-tested remediation</li>
              <li>• Clear rollback plan</li>
              <li>• Minimal user impact</li>
            </ul>
          </div>

          <div className="p-6 bg-gradient-to-br from-yellow-50 to-orange-50 rounded-xl">
            <h4 className="font-semibold text-slate-900 mb-2">
              Escalation Triggers
            </h4>
            <ul className="text-sm text-slate-600 space-y-1">
              <li>• High severity issues</li>
              <li>• Unknown failure patterns</li>
              <li>• Multi-system impact</li>
              <li>• Regulatory compliance</li>
            </ul>
          </div>

          <div className="p-6 bg-gradient-to-br from-red-50 to-pink-50 rounded-xl">
            <h4 className="font-semibold text-slate-900 mb-2">
              Override Conditions
            </h4>
            <ul className="text-sm text-slate-600 space-y-1">
              <li>• Emergency situations</li>
              <li>• Business critical systems</li>
              <li>• Time-sensitive fixes</li>
              <li>• Expert judgment required</li>
            </ul>
          </div>
        </div>
      </Section>
    </div>
  );
}
