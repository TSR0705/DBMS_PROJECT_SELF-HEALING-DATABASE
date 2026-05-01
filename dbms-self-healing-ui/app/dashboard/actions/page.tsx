'use client';

import { DataTable, DataTableColumn } from '@/components/ui-dbms/DataTable';
import { Section } from '@/components/ui-dbms/Section';
import { StatsCard } from '@/components/ui-dbms/StatsCard';
import { StatusBadge } from '@/components/ui-dbms/StatusBadge';
import { useRealtimeData } from '@/lib/realtime-service';
import type { HealingAction } from '@/lib/api';

export default function HealingActionsPage() {
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

  const { recentActions, systemMetrics } = data;

  // Calculate real stats from data using execution_status
  const successfulCount = recentActions.filter(
    a => a.execution_status === 'SUCCESS'
  ).length;
  const failedCount = recentActions.filter(
    a => a.execution_status === 'FAILED'
  ).length;
  const inProgressCount = recentActions.filter(
    a => a.execution_status === 'PENDING'
  ).length;

  const stats = {
    totalActions: recentActions.length,
    successful: successfulCount,
    failed: failedCount,
    pending: inProgressCount,
  };

  const columns: DataTableColumn<HealingAction>[] = [
    {
      key: 'action_id',
      header: 'ID',
      className: 'w-20',
      render: value => (
        <span className="font-mono text-xs bg-slate-100 px-2 py-1 rounded">
          {value ? `#${value}` : 'N/A'}
        </span>
      ),
    },
    {
      key: 'decision_id',
      header: 'Decision',
      className: 'w-20',
      render: value => (
        <span className="font-mono text-xs text-purple-600 font-bold">#{value}</span>
      ),
    },
    {
      key: 'action_type',
      header: 'Action Type',
      className: 'w-48',
      render: value => (
        <span className="font-semibold text-sm text-slate-800 tracking-tight">
          {value ? String(value).replace(/_/g, ' ') : 'Pending...'}
        </span>
      ),
    },
    {
      key: 'execution_mode',
      header: 'Mode',
      className: 'w-36',
      render: value => (
        <span
          className={`text-[10px] font-bold px-2.5 py-1 rounded-lg border shadow-sm tracking-tight ${
            value === 'AUTOMATIC'
              ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
              : value === 'MANUAL' 
                ? 'bg-amber-50 text-amber-700 border-amber-200'
                : 'bg-slate-50 text-slate-500 border-slate-200'
          }`}
        >
          {value ? String(value).replace(/_/g, ' ') : 'N/A'}
        </span>
      ),
    },
    {
      key: 'executed_by',
      header: 'Actor',
      className: 'w-32',
      render: value => (
        <span className="text-[11px] font-semibold text-slate-500 uppercase flex items-center">
          <div className={`w-1.5 h-1.5 rounded-full mr-2 ${value === 'SYSTEM' ? 'bg-blue-400' : value ? 'bg-purple-400' : 'bg-slate-300'}`}></div>
          {value || 'SYSTEM'}
        </span>
      ),
    },
    {
      key: 'execution_status',
      header: 'Status',
      className: 'w-32',
      render: value => <StatusBadge status={value} />,
    },
    {
      key: 'executed_at',
      header: 'Executed At',
      className: 'w-44',
      render: value => (
        <div>
          <div className="text-xs font-semibold text-slate-800">
            {value ? new Date(value).toLocaleDateString() : 'Pending'}
          </div>
          <div className="text-[11px] text-slate-500">
            {value ? new Date(value).toLocaleTimeString() : '...'}
          </div>
        </div>
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
              Healing Actions
            </h1>
            <p className="text-slate-600">
              Automated and manual healing actions executed to resolve database
              issues
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
          title="Total Actions"
          value={stats.totalActions}
          subtitle="Actions executed"
          trend="neutral"
        />
        <StatsCard
          title="Successful"
          value={stats.successful}
          subtitle="Completed successfully"
          trend={stats.successful > 0 ? 'up' : 'neutral'}
        />
        <StatsCard
          title="Failed"
          value={stats.failed}
          subtitle="Execution failed"
          trend={stats.failed > 0 ? 'down' : 'neutral'}
        />
        <StatsCard
          title="Pending"
          value={stats.pending}
          subtitle="In progress"
          trend={stats.pending > 0 ? 'up' : 'neutral'}
        />
      </div>

      {/* Actions Table */}
      <Section
        title="Action History"
        description="Complete log of all healing actions executed by the system"
      >
        <DataTable columns={columns} data={recentActions} loading={loading} />
      </Section>

      {/* Action Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Section
          title="Action Types"
          description="Distribution of healing action types"
        >
          <div className="space-y-4">
            {Array.from(new Set(recentActions.map(a => a.action_type))).map(
              actionType => {
                const count = recentActions.filter(
                  a => a.action_type === actionType
                ).length;
                const successRate =
                  (recentActions.filter(
                    a =>
                      a.action_type === actionType &&
                      a.execution_status === 'SUCCESS'
                  ).length /
                    count) *
                  100;

                return (
                  <div key={actionType} className="p-4 bg-slate-50 rounded-xl">
                    <div className="flex items-center justify-between mb-2">
                      <h4 className="font-semibold text-slate-900">
                        {actionType}
                      </h4>
                      <span className="text-sm text-slate-500">
                        {count} actions
                      </span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <span className="text-xs text-slate-600">
                        Success Rate:
                      </span>
                      <div className="w-20 bg-slate-200 rounded-full h-2">
                        <div
                          className="bg-green-500 h-2 rounded-full"
                          style={{ width: `${successRate || 0}%` }}
                        />
                      </div>
                      <span className="text-xs font-medium">
                        {Math.round(successRate || 0)}%
                      </span>
                    </div>
                  </div>
                );
              }
            )}
          </div>
        </Section>

        <Section
          title="Execution Status"
          description="Current status of healing actions"
        >
          <div className="space-y-4">
            {['SUCCESS', 'FAILED', 'PENDING'].map(status => {
              const count = recentActions.filter(
                a => a.execution_status === status
              ).length;
              const percentage =
                recentActions.length > 0
                  ? (count / recentActions.length) * 100
                  : 0;

              return (
                <div
                  key={status}
                  className="flex items-center justify-between p-4 bg-slate-50 rounded-xl"
                >
                  <div className="flex items-center space-x-3">
                    <StatusBadge
                      status={status}
                      variant={
                        status === 'SUCCESS'
                          ? 'success'
                          : status === 'FAILED'
                            ? 'error'
                            : status === 'PENDING'
                              ? 'warning'
                              : 'default'
                      }
                    />
                    <span className="font-medium">{count} actions</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="w-20 bg-slate-200 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full ${
                          status === 'SUCCESS'
                            ? 'bg-green-500'
                            : status === 'FAILED'
                              ? 'bg-red-500'
                              : status === 'PENDING'
                                ? 'bg-yellow-500'
                                : 'bg-blue-500'
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
      </div>

      {/* Recent Actions */}
      <Section
        title="Recent Actions"
        description="Latest healing actions executed by the system"
      >
        <div className="space-y-4">
          {recentActions.slice(0, 5).map((action, idx) => (
            <div
              key={action.action_id || `pending-${action.decision_id}-${idx}`}
              className="p-6 bg-white border border-slate-200 rounded-xl"
            >
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-3">
                  <span className="font-mono text-sm text-slate-500">
                    {action.action_id ? `#${action.action_id}` : 'QUEUED'}
                  </span>
                  <StatusBadge status={action.execution_status} />
                  <span
                    className={`text-xs px-2 py-1 rounded-full ${
                      action.execution_mode === 'AUTOMATIC'
                        ? 'bg-green-100 text-green-700'
                        : action.execution_mode === 'MANUAL'
                          ? 'bg-orange-100 text-orange-700'
                          : 'bg-slate-100 text-slate-700'
                    }`}
                  >
                    {action.execution_mode || 'PENDING'}
                  </span>
                </div>
                <span className="text-xs text-slate-500">
                  {action.executed_at ? new Date(action.executed_at).toLocaleString() : 'Waiting for execution...'}
                </span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                <div>
                  <span className="text-slate-600">Action Type:</span>
                  <p className="font-semibold text-slate-900">
                    {action.action_type || 'Identifying...'}
                  </p>
                </div>
                <div>
                  <span className="text-slate-600">Executed By:</span>
                  <p className="font-semibold text-slate-900">
                    {action.executed_by || 'SYSTEM'}
                  </p>
                </div>
                <div>
                  <span className="text-slate-600">Decision ID:</span>
                  <p className="font-mono text-purple-600">
                    #{action.decision_id}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </Section>
    </div>
  );
}
