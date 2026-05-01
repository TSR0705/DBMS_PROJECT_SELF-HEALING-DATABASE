import * as React from 'react';
import { PipelineEvent } from '@/types/dashboard';

interface PipelineViewProps {
  events: PipelineEvent[];
  loading?: boolean;
}

export function PipelineView({ events, loading }: PipelineViewProps) {
  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {[...Array(3)].map((_, i) => (
          <div key={i} className="bg-white border border-slate-200 rounded-lg p-6 animate-pulse">
            <div className="h-4 bg-slate-100 rounded w-1/4 mb-4" />
            <div className="h-6 bg-slate-100 rounded w-3/4 mb-6" />
            <div className="space-y-3">
              {[...Array(4)].map((_, j) => (
                <div key={j} className="h-3 bg-slate-100 rounded" />
              ))}
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (events.length === 0) {
    return (
      <div className="text-center py-12 bg-slate-50 border border-dashed border-slate-300 rounded-lg">
        <p className="text-slate-500 font-medium">System has no active issues in pipeline</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
      {events.map((event) => (
        <div key={`${event.issue_id}-${event.detected_at}`} className="bg-white border border-slate-200 rounded-lg overflow-hidden shadow-sm hover:shadow-md transition-shadow">
          {/* Header */}
          <div className="px-5 py-4 border-b border-slate-100 bg-slate-50/50 flex justify-between items-center">
            <div className="flex items-center space-x-2">
              <span className="font-mono text-xs font-bold text-slate-500">#{event.issue_id}</span>
              <h3 className="font-bold text-slate-900">{event.issue_type}</h3>
            </div>
            <StatusIndicator process={event.process_state} outcome={event.outcome} />
          </div>

          {/* Pipeline Flow */}
          <div className="p-5">
            <div className="relative pb-10">
              <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-slate-100" />
              
              <div className="space-y-6">
                <PipelineStep 
                  title="Detection" 
                  description={`Detected at ${new Date(event.detected_at).toLocaleTimeString()}`} 
                  active={true}
                  completed={true}
                />
                
                <PipelineStep 
                  title="AI Analysis" 
                  description={event.severity ? `${event.severity} Severity` : 'Pending...'} 
                  active={event.process_state === 'ANALYZED'}
                  completed={event.process_state !== 'ANALYZED'}
                  subtext={event.confidence > 0 ? `${(event.confidence * 100).toFixed(1)}% Confidence` : undefined}
                />

                <PipelineStep 
                  title="Decision" 
                  description={
                    event.outcome === 'REJECTED' ? 'REJECTED BY ADMIN' :
                    event.decision_type || 'Pending...'
                  } 
                  active={['DECIDED', 'WAITING_REVIEW'].includes(event.process_state)}
                  completed={!['ANALYZED', 'DECIDED', 'WAITING_REVIEW'].includes(event.process_state) || event.outcome === 'REJECTED'}
                />

                <PipelineStep 
                  title="Healing" 
                  description={
                    event.outcome === 'REJECTED' ? 'ACTION DISMISSED' :
                    event.action_type || 'Pending...'
                  } 
                  active={event.process_state === 'EXECUTING'}
                  completed={event.process_state === 'FINISHED'}
                  subtext={event.execution_status ? `Status: ${event.outcome}` : undefined}
                  last={true}
                />
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

function StatusIndicator({ process, outcome }: { process: PipelineEvent['process_state'], outcome: PipelineEvent['outcome'] }) {
  const configs = {
    SUCCESS: { label: 'Success', color: 'bg-green-500' },
    FAILED: { label: 'Failed', color: 'bg-red-500' },
    REJECTED: { label: 'Rejected', color: 'bg-slate-400' },
    SKIPPED: { label: 'Skipped', color: 'bg-indigo-300' },
    PENDING: { 
      label: process === 'WAITING_REVIEW' ? 'Waiting Review' : 
             process === 'EXECUTING' ? 'Executing' :
             process === 'FINISHED' ? 'Finished' : 'Processing', 
      color: process === 'WAITING_REVIEW' ? 'bg-amber-500' : 
             process === 'EXECUTING' ? 'bg-blue-500' : 'bg-indigo-500' 
    },
  };

  const config = configs[outcome as keyof typeof configs] || configs.PENDING;
  
  return (
    <div className="flex items-center space-x-1.5">
      <div className={`w-2 h-2 rounded-full ${config.color} ${outcome === 'PENDING' ? 'animate-pulse' : ''}`} />
      <span className="text-[10px] font-bold uppercase tracking-wider text-slate-600">{config.label}</span>
    </div>
  );
}

function PipelineStep({ 
  title, 
  description, 
  active, 
  completed, 
  subtext,
  last = false 
}: { 
  title: string; 
  description: string; 
  active: boolean; 
  completed: boolean; 
  subtext?: string;
  last?: boolean;
}) {
  return (
    <div className="relative flex items-start space-x-4">
      <div className={`z-10 flex items-center justify-center w-8 h-8 rounded-full border-2 transition-colors duration-300 ${
        completed ? 'bg-green-500 border-green-500' : 
        active ? 'bg-white border-blue-500' : 'bg-white border-slate-200'
      }`}>
        {completed ? (
          <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
          </svg>
        ) : (
          <div className={`w-2 h-2 rounded-full ${active ? 'bg-blue-500 animate-pulse' : 'bg-slate-200'}`} />
        )}
      </div>
      
      <div className="flex-1 pt-0.5">
        <h4 className={`text-xs font-bold uppercase tracking-tight ${active ? 'text-slate-900' : 'text-slate-400'}`}>{title}</h4>
        <p className={`text-sm ${active ? 'text-slate-600 font-medium' : 'text-slate-400'}`}>{description}</p>
        {subtext && active && (
          <p className="text-[10px] mt-1 font-mono text-slate-500 bg-slate-50 inline-block px-1.5 py-0.5 rounded border border-slate-100">
            {subtext}
          </p>
        )}
      </div>
    </div>
  );
}
