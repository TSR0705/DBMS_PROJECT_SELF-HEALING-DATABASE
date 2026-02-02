'use client';

import { useEffect, useState } from 'react';
import { DataTable, DataTableColumn } from '@/components/ui-dbms/DataTable';
import { Section } from '@/components/ui-dbms/Section';
import { StatsCard } from '@/components/ui-dbms/StatsCard';
import { StatusBadge } from '@/components/ui-dbms/StatusBadge';
import { apiClient, LearningHistory } from '@/lib/api';

export default function LearningPage() {
  const [learningRecords, setLearningRecords] = useState<LearningHistory[]>([]);
  const [improvementStats, setImprovementStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalRecords: 0,
    resolved: 0,
    avgImprovement: 0,
    bestPerforming: 'Unknown',
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const [learningData, statsData] = await Promise.all([
          apiClient.getAllLearningHistory(),
          apiClient.getLearningImprovementStats().catch(() => null),
        ]);

        setLearningRecords(learningData);
        setImprovementStats(statsData);

        // Calculate stats
        const resolvedCount = learningData.filter(
          l => l.outcome === 'RESOLVED'
        ).length;
        const avgImprovement =
          learningData.length > 0
            ? learningData.reduce(
                (sum, l) => sum + (l.confidence_after - l.confidence_before),
                0
              ) / learningData.length
            : 0;

        const bestPerforming =
          statsData?.learning_stats?.length > 0
            ? statsData.learning_stats[0].issue_type
            : 'Unknown';

        setStats({
          totalRecords: learningData.length,
          resolved: resolvedCount,
          avgImprovement: Math.round(avgImprovement * 100),
          bestPerforming,
        });
      } catch (error) {
        console.error('Error fetching learning data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  const columns: DataTableColumn<LearningHistory>[] = [
    {
      key: 'learning_id',
      header: 'Learning ID',
      render: value => (
        <span className="font-mono text-sm bg-slate-100 px-2 py-1 rounded">
          #{value}
        </span>
      ),
    },
    {
      key: 'issue_type',
      header: 'Issue Type',
      render: value => (
        <span className="font-semibold text-slate-900 bg-blue-50 px-2 py-1 rounded">
          {value}
        </span>
      ),
    },
    {
      key: 'action_type',
      header: 'Action Type',
      render: value => (
        <span className="text-sm text-slate-600 bg-green-50 px-2 py-1 rounded">
          {value}
        </span>
      ),
    },
    {
      key: 'outcome',
      header: 'Outcome',
      render: value => {
        const variant =
          value === 'RESOLVED'
            ? 'success'
            : value === 'FAILED'
              ? 'error'
              : 'warning';
        return <StatusBadge status={value} variant={variant} />;
      },
    },
    {
      key: 'confidence_before',
      header: 'Before',
      render: value => (
        <div className="flex items-center space-x-2">
          <div className="w-12 bg-slate-200 rounded-full h-2">
            <div
              className="bg-red-400 h-2 rounded-full"
              style={{ width: `${value * 100}%` }}
            />
          </div>
          <span className="text-xs font-medium">
            {Math.round(value * 100)}%
          </span>
        </div>
      ),
    },
    {
      key: 'confidence_after',
      header: 'After',
      render: value => (
        <div className="flex items-center space-x-2">
          <div className="w-12 bg-slate-200 rounded-full h-2">
            <div
              className="bg-green-500 h-2 rounded-full"
              style={{ width: `${value * 100}%` }}
            />
          </div>
          <span className="text-xs font-medium">
            {Math.round(value * 100)}%
          </span>
        </div>
      ),
    },
    {
      key: 'recorded_at',
      header: 'Recorded At',
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
        <h1 className="text-3xl font-bold text-slate-900 mb-2">
          Learning History
        </h1>
        <p className="text-slate-600">
          System learning and improvement tracking for continuous enhancement
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <StatsCard
          title="Learning Records"
          value={stats.totalRecords}
          subtitle="Total learning events"
          trend="neutral"
        />
        <StatsCard
          title="Resolved Cases"
          value={stats.resolved}
          subtitle="Successful outcomes"
          trend={stats.resolved > 0 ? 'up' : 'neutral'}
        />
        <StatsCard
          title="Avg Improvement"
          value={`${stats.avgImprovement}%`}
          subtitle="Confidence gain"
          trend={stats.avgImprovement > 0 ? 'up' : 'neutral'}
        />
        <StatsCard
          title="Best Performing"
          value={stats.bestPerforming}
          subtitle="Issue type"
          trend="neutral"
        />
      </div>

      {/* Learning History Table */}
      <Section
        title="Learning Records"
        description="Complete history of system learning and confidence improvements"
      >
        <DataTable columns={columns} data={learningRecords} loading={loading} />
      </Section>

      {/* Learning Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Section
          title="Improvement Statistics"
          description="Performance improvements by issue and action type"
        >
          <div className="space-y-4">
            {improvementStats?.learning_stats?.slice(0, 5).map((stat: any) => (
              <div
                key={`${stat.issue_type}-${stat.action_type}`}
                className="p-4 bg-white border border-slate-200 rounded-xl"
              >
                <div className="flex items-center justify-between mb-2">
                  <h4 className="font-semibold text-slate-900">
                    {stat.issue_type}
                  </h4>
                  <span className="text-sm text-slate-500">
                    {stat.total_records} records
                  </span>
                </div>
                <p className="text-sm text-slate-600 mb-3">
                  {stat.action_type}
                </p>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-slate-600">Success Rate:</span>
                    <p className="font-semibold text-green-600">
                      {Math.round(stat.success_rate)}%
                    </p>
                  </div>
                  <div>
                    <span className="text-slate-600">Avg Improvement:</span>
                    <p className="font-semibold text-blue-600">
                      +{Math.round(stat.avg_improvement * 100)}%
                    </p>
                  </div>
                </div>
              </div>
            )) || (
              <div className="text-center py-8 text-slate-500">
                No improvement statistics available
              </div>
            )}
          </div>
        </Section>

        <Section
          title="Outcome Distribution"
          description="Distribution of learning outcomes"
        >
          <div className="space-y-4">
            {['RESOLVED', 'FAILED', 'PARTIAL'].map(outcome => {
              const count = learningRecords.filter(
                l => l.outcome === outcome
              ).length;
              const percentage =
                learningRecords.length > 0
                  ? (count / learningRecords.length) * 100
                  : 0;

              return (
                <div
                  key={outcome}
                  className="flex items-center justify-between p-4 bg-slate-50 rounded-xl"
                >
                  <div className="flex items-center space-x-3">
                    <StatusBadge
                      status={outcome}
                      variant={
                        outcome === 'RESOLVED'
                          ? 'success'
                          : outcome === 'FAILED'
                            ? 'error'
                            : 'warning'
                      }
                    />
                    <span className="font-medium">{count} cases</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="w-20 bg-slate-200 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full ${
                          outcome === 'RESOLVED'
                            ? 'bg-green-500'
                            : outcome === 'FAILED'
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
      </div>

      {/* Learning Insights */}
      <Section
        title="Learning Insights"
        description="Key insights from system learning and improvement"
      >
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="p-6 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl">
            <h4 className="font-semibold text-slate-900 mb-2">
              Confidence Growth
            </h4>
            <p className="text-sm text-slate-600 mb-4">
              System confidence improves with each learning cycle
            </p>
            <div className="flex items-center space-x-2">
              <div className="w-16 bg-blue-200 rounded-full h-2">
                <div
                  className="bg-blue-500 h-2 rounded-full"
                  style={{ width: '85%' }}
                />
              </div>
              <span className="text-sm font-medium text-blue-600">85%</span>
            </div>
          </div>

          <div className="p-6 bg-gradient-to-br from-green-50 to-emerald-50 rounded-xl">
            <h4 className="font-semibold text-slate-900 mb-2">Success Rate</h4>
            <p className="text-sm text-slate-600 mb-4">
              High success rate in resolving detected issues
            </p>
            <div className="flex items-center space-x-2">
              <div className="w-16 bg-green-200 rounded-full h-2">
                <div
                  className="bg-green-500 h-2 rounded-full"
                  style={{ width: '92%' }}
                />
              </div>
              <span className="text-sm font-medium text-green-600">92%</span>
            </div>
          </div>

          <div className="p-6 bg-gradient-to-br from-purple-50 to-violet-50 rounded-xl">
            <h4 className="font-semibold text-slate-900 mb-2">
              Learning Velocity
            </h4>
            <p className="text-sm text-slate-600 mb-4">
              Rapid learning and adaptation to new patterns
            </p>
            <div className="flex items-center space-x-2">
              <div className="w-16 bg-purple-200 rounded-full h-2">
                <div
                  className="bg-purple-500 h-2 rounded-full"
                  style={{ width: '78%' }}
                />
              </div>
              <span className="text-sm font-medium text-purple-600">78%</span>
            </div>
          </div>
        </div>
      </Section>
    </div>
  );
}
