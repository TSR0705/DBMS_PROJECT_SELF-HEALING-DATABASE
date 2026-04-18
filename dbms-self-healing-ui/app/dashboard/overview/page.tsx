'use client';

import * as React from 'react';
import { StatsCard } from '@/components/ui-dbms/StatsCard';
import { Section } from '@/components/ui-dbms/Section';
import { DataTable, DataTableColumn } from '@/components/ui-dbms/DataTable';
import { PipelineView } from '@/components/ui-dbms/PipelineView';
import { useRealtimeData, realtimeService } from '@/lib/realtime-service';
import { apiClient } from '@/lib/api';
import { AdminReview, LearningHistory } from '@/types/dashboard';

export default function SystemOverview() {
  const { data, loading, refresh } = useRealtimeData();
  const [processingId, setProcessingId] = React.useState<string | null>(null);

  if (loading || !data) {
    return (
      <div className="p-8 space-y-8 animate-pulse">
        <div className="h-10 bg-slate-200 rounded w-1/4 mb-4" />
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-32 bg-slate-200 rounded-lg" />
          ))}
        </div>
        <div className="h-64 bg-slate-200 rounded-lg" />
      </div>
    );
  }

  const { systemMetrics, recentReviews, recentLearning, recentEvents } = data;

  const handleApprove = async (reviewId: string) => {
    setProcessingId(reviewId);
    try {
      await apiClient.approveReview(reviewId);
      await realtimeService.refreshData();
    } catch (err) {
      console.error('Failed to approve:', err);
    } finally {
      setProcessingId(null);
    }
  };

  const handleReject = async (reviewId: string) => {
    setProcessingId(reviewId);
    try {
      await apiClient.rejectReview(reviewId);
      await realtimeService.refreshData();
    } catch (err) {
      console.error('Failed to reject:', err);
    } finally {
      setProcessingId(null);
    }
  };

  // 1. Admin Review Columns (Prioritized)
  const reviewColumns: DataTableColumn<AdminReview>[] = [
    {
      key: 'issue_type',
      header: 'Issue Type',
      render: (val, row) => (
        <div className="flex flex-col">
          <span className="font-bold text-slate-900">{val}</span>
          <span className="text-[10px] text-slate-500 font-mono">ID: #{row.review_id}</span>
        </div>
      ),
    },
    {
      key: 'review_status',
      header: 'Status & Priority',
      render: (val, row) => (
        <div className="flex items-center space-x-2">
          <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${
            val === 'PENDING' ? 'bg-amber-100 text-amber-700' : 'bg-slate-100 text-slate-700'
          }`}>
            {val}
          </span>
          <RiskIndicator issueId={row.issue_id} analysis={data.recentAnalysis} />
        </div>
      ),
    },
    {
      key: 'decision_id',
      header: 'Confidence',
      render: (_, row) => {
        const analysis = data.recentAnalysis.find(a => a.issue_id === row.issue_id);
        const score = analysis?.confidence_score || 0;
        return <ConfidenceBar score={score} />;
      },
    },
    {
      key: 'action_type',
      header: 'Suggested Action',
      render: (val) => (
        <span className="font-medium text-blue-700 bg-blue-50 px-2 py-1 rounded text-xs border border-blue-100 italic">
          {val || 'PENDING ANALYSIS'}
        </span>
      ),
    },
    {
      key: 'review_id',
      header: 'Actions',
      className: 'text-right',
      render: (val, row) => (
        <div className="flex justify-end space-x-2">
          {row.review_status === 'PENDING' ? (
            <>
              <button
                disabled={!!processingId}
                onClick={() => handleApprove(String(val))}
                className="bg-green-600 hover:bg-green-700 text-white text-[10px] font-bold py-1.5 px-3 rounded shadow-sm transition-all disabled:opacity-50"
              >
                {processingId === String(val) ? '...' : 'APPROVE'}
              </button>
              <button
                disabled={!!processingId}
                onClick={() => handleReject(String(val))}
                className="bg-white border border-red-200 text-red-600 hover:bg-red-50 text-[10px] font-bold py-1.5 px-3 rounded shadow-sm transition-all disabled:opacity-50"
              >
                REJECT
              </button>
            </>
          ) : (
            <span className="text-xs text-slate-400 font-medium italic">Action Taken</span>
          )}
        </div>
      ),
    },
  ];

  // 2. Learning History Columns
  const learningColumns: DataTableColumn<LearningHistory>[] = [
    { key: 'issue_type', header: 'Problem' },
    { key: 'action_type', header: 'Remedy' },
    { 
      key: 'outcome', 
      header: 'Outcome',
      render: (val) => (
        <span className={`font-bold text-xs ${val === 'RESOLVED' ? 'text-green-600' : 'text-amber-600'}`}>
          {val}
        </span>
      )
    },
    {
      key: 'confidence_after',
      header: 'Learning Impact',
      render: (_, row) => (
        <div className="flex items-center space-x-2">
          <span className="text-xs text-slate-500 line-through">{(row.confidence_before * 100).toFixed(0)}%</span>
          <span className="text-green-600 font-bold">→ {(row.confidence_after * 100).toFixed(0)}%</span>
          <span className="text-[10px] bg-green-50 text-green-700 px-1.5 py-0.5 rounded border border-green-100">
            +{( (row.confidence_after - row.confidence_before) * 100).toFixed(1)}%
          </span>
        </div>
      )
    }
  ];

  return (
    <div className="p-8 space-y-10 max-w-[1600px] mx-auto">
      {/* Header Section */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 border-b border-slate-200 pb-8">
        <div>
          <h1 className="text-4xl font-extrabold text-slate-900 tracking-tight">System Control Panel</h1>
          <p className="text-slate-500 mt-2 font-medium">Real-time Autonomous Decision Infrastructure</p>
        </div>
        <div className="flex items-center space-x-6 bg-slate-50 px-4 py-2 rounded-lg border border-slate-100">
          <div className="flex items-center space-x-2">
            <div className={`w-2.5 h-2.5 rounded-full ${systemMetrics.isConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`}></div>
            <span className="text-xs font-bold uppercase tracking-widest text-slate-600">
              {systemMetrics.isConnected ? 'Live' : 'Offline'}
            </span>
          </div>
          <div className="h-4 w-px bg-slate-200" />
          <div className="text-xs font-mono text-slate-500">
            Node Refresh: <span className="text-slate-900 font-bold">{systemMetrics.lastUpdate.toLocaleTimeString()}</span>
          </div>
          <button 
            onClick={refresh} 
            className="p-1.5 hover:bg-slate-200 rounded-full transition-colors text-slate-400"
            title="Manual Sync"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
          </button>
        </div>
      </div>

      {/* 1. Status Cards Layer */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatsCard
          title="Total Issues"
          value={systemMetrics.totalIssues}
          subtitle="All detected anomalies"
          trend={systemMetrics.totalIssues > 0 ? 'up' : 'neutral'}
          className="rounded-xl border-l-4 border-l-blue-500"
        />
        <StatsCard
          title="Critical Issues"
          value={systemMetrics.criticalIssues}
          subtitle="Action required immediately"
          trend={systemMetrics.criticalIssues > 0 ? 'up' : 'neutral'}
          className="rounded-xl border-l-4 border-l-red-500"
        />
        <StatsCard
          title="Auto-Healed"
          value={systemMetrics.autoHealedCount}
          subtitle="Zero-touch resolutions"
          trend="up"
          className="rounded-xl border-l-4 border-l-green-500"
        />
        <StatsCard
          title="Pending Reviews"
          value={systemMetrics.pendingReviews}
          subtitle="Human-in-the-loop queue"
          trend="neutral"
          className="rounded-xl border-l-4 border-l-amber-500"
        />
      </div>

      {/* 2. Pipeline Layer */}
      <Section 
        title="Active Pipeline View" 
        description="Live visualization of issue progression through AI analysis and healing steps."
        className="bg-transparent border-none p-0"
      >
        <PipelineView events={recentEvents} />
      </Section>

      {/* 3. Action Layer (Smart Tables) */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
        <div className="xl:col-span-2">
          <Section title="Admin Control Center" description="Prioritized manual review requests requiring expert intervention.">
            <DataTable 
              columns={reviewColumns} 
              data={recentReviews} 
              expandableRender={(row) => <ReviewDetails row={row} data={data} />}
            />
          </Section>
        </div>
        <div>
          <Section title="Learning Ecosystem" description="Post-action confidence improvements.">
            <DataTable columns={learningColumns} data={recentLearning} />
          </Section>
        </div>
      </div>
    </div>
  );
}

function ConfidenceBar({ score }: { score: number }) {
  const percentage = Math.round(score * 100);
  const color = percentage > 80 ? 'bg-green-500' : percentage > 50 ? 'bg-amber-500' : 'bg-red-500';
  
  return (
    <div className="w-full max-w-[120px] space-y-1">
      <div className="flex justify-between text-[10px] font-bold">
        <span>{percentage}%</span>
      </div>
      <div className="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
        <div 
          className={`h-full ${color} transition-all duration-1000`} 
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  );
}

function RiskIndicator({ issueId, analysis }: { issueId: string, analysis: any[] }) {
  const item = analysis.find(a => a.issue_id === issueId);
  const type = item?.risk_type || 'UNKNOWN';
  
  const configs: Record<string, { label: string, color: string }> = {
    STATIC: { label: 'Static Risk', color: 'text-slate-500 bg-slate-50 border-slate-200' },
    DYNAMIC: { label: 'Dynamic Spike', color: 'text-amber-600 bg-amber-50 border-amber-200' },
    SLA_VIOLATION: { label: 'SLA Risk', color: 'text-red-600 bg-red-50 border-red-200' },
    UNKNOWN: { label: 'Audit Risk', color: 'text-slate-400 bg-slate-50 border-slate-100' },
  };

  const config = configs[type];

  return (
    <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase border ${config.color}`}>
      {config.label}
    </span>
  );
}

function ReviewDetails({ row, data }: { row: AdminReview, data: any }) {
  const decision = data.recentDecisions.find((d: any) => d.decision_id === row.decision_id);
  
  return (
    <div className="grid grid-cols-2 gap-8 text-sm">
      <div className="space-y-2">
        <h5 className="font-bold text-slate-500 uppercase text-[10px] tracking-widest">Decision Rationale</h5>
        <div className="bg-white border border-slate-200 p-3 rounded-lg text-slate-700 italic font-medium leading-relaxed">
           "{decision?.decision_reason || 'System is requesting manual verification before proceeding with intensive healing logic.'}"
        </div>
      </div>
      <div className="space-y-2">
        <h5 className="font-bold text-slate-500 uppercase text-[10px] tracking-widest">Technical metadata</h5>
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white border border-slate-100 p-2 rounded">
            <span className="block text-[10px] text-slate-400 uppercase font-bold">Override Flag</span>
            <span className="font-mono font-bold text-slate-900">{row.override_flag ? 'TRUE' : 'FALSE'}</span>
          </div>
          <div className="bg-white border border-slate-100 p-2 rounded">
            <span className="block text-[10px] text-slate-400 uppercase font-bold">Review ID</span>
            <span className="font-mono font-bold text-slate-900">#{row.review_id}</span>
          </div>
        </div>
      </div>
    </div>
  );
}
