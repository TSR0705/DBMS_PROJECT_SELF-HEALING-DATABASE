'use client';

import { useEffect, useState } from "react";
import { DataTable, DataTableColumn } from "@/components/ui-dbms/DataTable";
import { Section } from "@/components/ui-dbms/Section";
import { StatsCard } from "@/components/ui-dbms/StatsCard";
import { StatusBadge } from "@/components/ui-dbms/StatusBadge";
import { apiClient, HealingAction } from "@/lib/api";

export default function HealingActionsPage() {
  const [actions, setActions] = useState<HealingAction[]>([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalActions: 0,
    successful: 0,
    failed: 0,
    pending: 0
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const actionData = await apiClient.getHealingActions();
        setActions(actionData);

        // Calculate stats
        const successfulCount = actionData.filter(a => a.execution_status === 'SUCCESS').length;
        const failedCount = actionData.filter(a => a.execution_status === 'FAILED').length;
        const pendingCount = actionData.filter(a => a.execution_status === 'PENDING').length;

        setStats({
          totalActions: actionData.length,
          successful: successfulCount,
          failed: failedCount,
          pending: pendingCount
        });
      } catch (error) {
        console.error('Error fetching healing actions:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  const columns: DataTableColumn<HealingAction>[] = [
    {
      key: 'action_id',
      header: 'Action ID',
      render: (value) => (
        <span className="font-mono text-sm bg-slate-100 px-2 py-1 rounded">
          #{value}
        </span>
      )
    },
    {
      key: 'decision_id',
      header: 'Decision ID',
      render: (value) => (
        <span className="font-mono text-sm text-purple-600">
          #{value}
        </span>
      )
    },
    {
      key: 'action_type',
      header: 'Action Type',
      render: (value) => (
        <span className="font-semibold text-slate-900 bg-blue-50 px-2 py-1 rounded">
          {value}
        </span>
      )
    },
    {
      key: 'execution_mode',
      header: 'Mode',
      render: (value) => (
        <span className={`text-xs px-2 py-1 rounded-full ${
          value === 'AUTOMATIC' ? 'bg-green-100 text-green-700' : 'bg-orange-100 text-orange-700'
        }`}>
          {value}
        </span>
      )
    },
    {
      key: 'executed_by',
      header: 'Executed By',
      render: (value) => (
        <span className="text-sm text-slate-600">
          {value}
        </span>
      )
    },
    {
      key: 'execution_status',
      header: 'Status',
      render: (value) => {
        const variant = value === 'SUCCESS' ? 'success' : 
                       value === 'FAILED' ? 'error' : 
                       value === 'PENDING' ? 'warning' : 'default';
        return <StatusBadge status={value} variant={variant} />;
      }
    },
    {
      key: 'executed_at',
      header: 'Executed At',
      render: (value) => (
        <span className="text-sm text-slate-500">
          {new Date(value).toLocaleString()}
        </span>
      )
    }
  ];

  return (
    <div className="space-y-8">
      {/* Page Header */}
      <div className="border-b border-slate-200 pb-6">
        <h1 className="text-3xl font-bold text-slate-900 mb-2">Healing Actions</h1>
        <p className="text-slate-600">
          Automated and manual healing actions executed to resolve database issues
        </p>
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
          trend={stats.successful > 0 ? "up" : "neutral"}
        />
        <StatsCard
          title="Failed"
          value={stats.failed}
          subtitle="Execution failed"
          trend={stats.failed > 0 ? "down" : "neutral"}
        />
        <StatsCard
          title="Pending"
          value={stats.pending}
          subtitle="In progress"
          trend={stats.pending > 0 ? "up" : "neutral"}
        />
      </div>

      {/* Actions Table */}
      <Section
        title="Action History"
        description="Complete log of all healing actions executed by the system"
      >
        <DataTable
          columns={columns}
          data={actions}
          loading={loading}
        />
      </Section>

      {/* Action Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Section
          title="Action Types"
          description="Distribution of healing action types"
        >
          <div className="space-y-4">
            {Array.from(new Set(actions.map(a => a.action_type))).map(actionType => {
              const count = actions.filter(a => a.action_type === actionType).length;
              const successRate = actions.filter(a => a.action_type === actionType && a.execution_status === 'SUCCESS').length / count * 100;
              
              return (
                <div key={actionType} className="p-4 bg-slate-50 rounded-xl">
                  <div className="flex items-center justify-between mb-2">
                    <h4 className="font-semibold text-slate-900">{actionType}</h4>
                    <span className="text-sm text-slate-500">{count} actions</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="text-xs text-slate-600">Success Rate:</span>
                    <div className="w-20 bg-slate-200 rounded-full h-2">
                      <div 
                        className="bg-green-500 h-2 rounded-full" 
                        style={{ width: `${successRate || 0}%` }}
                      />
                    </div>
                    <span className="text-xs font-medium">{Math.round(successRate || 0)}%</span>
                  </div>
                </div>
              );
            })}
          </div>
        </Section>

        <Section
          title="Execution Status"
          description="Current status of healing actions"
        >
          <div className="space-y-4">
            {['SUCCESS', 'FAILED', 'PENDING', 'IN_PROGRESS'].map(status => {
              const count = actions.filter(a => a.execution_status === status).length;
              const percentage = actions.length > 0 ? (count / actions.length) * 100 : 0;
              
              return (
                <div key={status} className="flex items-center justify-between p-4 bg-slate-50 rounded-xl">
                  <div className="flex items-center space-x-3">
                    <StatusBadge 
                      status={status} 
                      variant={status === 'SUCCESS' ? 'success' : 
                              status === 'FAILED' ? 'error' : 
                              status === 'PENDING' ? 'warning' : 'default'} 
                    />
                    <span className="font-medium">{count} actions</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="w-20 bg-slate-200 rounded-full h-2">
                      <div 
                        className={`h-2 rounded-full ${
                          status === 'SUCCESS' ? 'bg-green-500' :
                          status === 'FAILED' ? 'bg-red-500' :
                          status === 'PENDING' ? 'bg-yellow-500' : 'bg-blue-500'
                        }`}
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                    <span className="text-sm text-slate-600">{Math.round(percentage)}%</span>
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
          {actions.slice(0, 5).map((action) => (
            <div key={action.action_id} className="p-6 bg-white border border-slate-200 rounded-xl">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-3">
                  <span className="font-mono text-sm text-slate-500">#{action.action_id}</span>
                  <StatusBadge 
                    status={action.execution_status} 
                    variant={action.execution_status === 'SUCCESS' ? 'success' : 
                            action.execution_status === 'FAILED' ? 'error' : 'warning'} 
                  />
                  <span className={`text-xs px-2 py-1 rounded-full ${
                    action.execution_mode === 'AUTOMATIC' ? 'bg-green-100 text-green-700' : 'bg-orange-100 text-orange-700'
                  }`}>
                    {action.execution_mode}
                  </span>
                </div>
                <span className="text-xs text-slate-500">
                  {new Date(action.executed_at).toLocaleString()}
                </span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                <div>
                  <span className="text-slate-600">Action Type:</span>
                  <p className="font-semibold text-slate-900">{action.action_type}</p>
                </div>
                <div>
                  <span className="text-slate-600">Executed By:</span>
                  <p className="font-semibold text-slate-900">{action.executed_by}</p>
                </div>
                <div>
                  <span className="text-slate-600">Decision ID:</span>
                  <p className="font-mono text-purple-600">#{action.decision_id}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </Section>
    </div>
  );
}