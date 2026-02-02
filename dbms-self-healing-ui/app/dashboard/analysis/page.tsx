'use client';

import { useEffect, useState } from "react";
import { DataTable, DataTableColumn } from "@/components/ui-dbms/DataTable";
import { Section } from "@/components/ui-dbms/Section";
import { StatsCard } from "@/components/ui-dbms/StatsCard";
import { StatusBadge } from "@/components/ui-dbms/StatusBadge";
import { apiClient, AIAnalysis } from "@/lib/api";

export default function AIAnalysisPage() {
  const [analyses, setAnalyses] = useState<AIAnalysis[]>([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalAnalyses: 0,
    highSeverity: 0,
    avgConfidence: 0,
    latestModel: 'Unknown'
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const analysisData = await apiClient.getAllAnalysis();
        setAnalyses(analysisData);

        // Calculate stats
        const highSeverityCount = analysisData.filter(a => a.severity_level === 'HIGH').length;
        const avgConf = analysisData.length > 0 
          ? analysisData.reduce((sum, a) => sum + a.confidence_score, 0) / analysisData.length 
          : 0;
        const latestModel = analysisData.length > 0 ? analysisData[0].model_version : 'Unknown';

        setStats({
          totalAnalyses: analysisData.length,
          highSeverity: highSeverityCount,
          avgConfidence: Math.round(avgConf * 100),
          latestModel
        });
      } catch (error) {
        console.error('Error fetching analysis data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  const columns: DataTableColumn<AIAnalysis>[] = [
    {
      key: 'analysis_id',
      header: 'Analysis ID',
      render: (value) => (
        <span className="font-mono text-sm bg-slate-100 px-2 py-1 rounded">
          #{value}
        </span>
      )
    },
    {
      key: 'issue_id',
      header: 'Issue ID',
      render: (value) => (
        <span className="font-mono text-sm text-blue-600">
          #{value}
        </span>
      )
    },
    {
      key: 'predicted_issue_class',
      header: 'Predicted Class',
      render: (value) => (
        <span className="font-semibold text-slate-900">
          {value}
        </span>
      )
    },
    {
      key: 'severity_level',
      header: 'Severity',
      render: (value) => {
        const variant = value === 'HIGH' ? 'error' : value === 'MEDIUM' ? 'warning' : 'success';
        return <StatusBadge status={value} variant={variant} />;
      }
    },
    {
      key: 'risk_type',
      header: 'Risk Type',
      render: (value) => (
        <span className="text-sm text-slate-600 bg-orange-50 px-2 py-1 rounded">
          {value}
        </span>
      )
    },
    {
      key: 'confidence_score',
      header: 'Confidence',
      render: (value) => (
        <div className="flex items-center space-x-2">
          <div className="w-16 bg-slate-200 rounded-full h-2">
            <div 
              className="bg-green-500 h-2 rounded-full" 
              style={{ width: `${value * 100}%` }}
            />
          </div>
          <span className="text-sm font-medium">{Math.round(value * 100)}%</span>
        </div>
      )
    },
    {
      key: 'model_version',
      header: 'Model',
      render: (value) => (
        <span className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded-full">
          {value}
        </span>
      )
    },
    {
      key: 'analyzed_at',
      header: 'Analyzed At',
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
        <h1 className="text-3xl font-bold text-slate-900 mb-2">AI Analysis</h1>
        <p className="text-slate-600">
          Machine learning analysis results for detected database issues
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <StatsCard
          title="Total Analyses"
          value={stats.totalAnalyses}
          subtitle="AI predictions made"
          trend="neutral"
        />
        <StatsCard
          title="High Severity"
          value={stats.highSeverity}
          subtitle="Critical issues found"
          trend={stats.highSeverity > 0 ? "up" : "neutral"}
        />
        <StatsCard
          title="Avg Confidence"
          value={`${stats.avgConfidence}%`}
          subtitle="Model accuracy"
          trend={stats.avgConfidence > 80 ? "up" : "neutral"}
        />
        <StatsCard
          title="Model Version"
          value={stats.latestModel}
          subtitle="Current AI model"
          trend="neutral"
        />
      </div>

      {/* Analysis Results Table */}
      <Section
        title="Analysis Results"
        description="Detailed AI analysis results for each detected issue"
      >
        <DataTable
          columns={columns}
          data={analyses}
          loading={loading}
        />
      </Section>

      {/* Analysis Insights */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Section
          title="Severity Distribution"
          description="Breakdown of issue severity levels"
        >
          <div className="space-y-4">
            {['HIGH', 'MEDIUM', 'LOW'].map(severity => {
              const count = analyses.filter(a => a.severity_level === severity).length;
              const percentage = analyses.length > 0 ? (count / analyses.length) * 100 : 0;
              
              return (
                <div key={severity} className="flex items-center justify-between p-4 bg-slate-50 rounded-xl">
                  <div className="flex items-center space-x-3">
                    <StatusBadge 
                      status={severity} 
                      variant={severity === 'HIGH' ? 'error' : severity === 'MEDIUM' ? 'warning' : 'success'} 
                    />
                    <span className="font-medium">{count} issues</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="w-20 bg-slate-200 rounded-full h-2">
                      <div 
                        className={`h-2 rounded-full ${
                          severity === 'HIGH' ? 'bg-red-500' :
                          severity === 'MEDIUM' ? 'bg-yellow-500' : 'bg-green-500'
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

        <Section
          title="Risk Types"
          description="Categories of risks identified by AI"
        >
          <div className="space-y-4">
            {Array.from(new Set(analyses.map(a => a.risk_type))).map(riskType => {
              const count = analyses.filter(a => a.risk_type === riskType).length;
              const avgConfidence = analyses
                .filter(a => a.risk_type === riskType)
                .reduce((sum, a) => sum + a.confidence_score, 0) / count;
              
              return (
                <div key={riskType} className="p-4 bg-white border border-slate-200 rounded-xl">
                  <div className="flex items-center justify-between mb-2">
                    <h4 className="font-semibold text-slate-900">{riskType}</h4>
                    <span className="text-sm text-slate-500">{count} cases</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="text-xs text-slate-600">Avg Confidence:</span>
                    <div className="w-16 bg-slate-200 rounded-full h-1.5">
                      <div 
                        className="bg-blue-500 h-1.5 rounded-full" 
                        style={{ width: `${(avgConfidence || 0) * 100}%` }}
                      />
                    </div>
                    <span className="text-xs font-medium">{Math.round((avgConfidence || 0) * 100)}%</span>
                  </div>
                </div>
              );
            })}
          </div>
        </Section>
      </div>
    </div>
  );
}