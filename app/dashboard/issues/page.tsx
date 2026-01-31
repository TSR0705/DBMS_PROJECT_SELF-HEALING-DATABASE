import { DataTable, DataTableColumn } from "@/components/ui-dbms/DataTable";
import { Section } from "@/components/ui-dbms/Section";
import { Badge } from "@/components/ui/badge";

// Issue data structure for DBMS monitoring
interface DetectedIssue {
  issueId: string;
  issueType: string;
  source: string;
  detectedAt: string;
  status: string;
  severity: string;
}

// Static mock data representing realistic DBMS issues
const mockIssues: DetectedIssue[] = [
  {
    issueId: "ISS-2024-001",
    issueType: "High CPU Usage",
    source: "Performance Monitor",
    detectedAt: "2024-01-31 14:23:15",
    status: "Active",
    severity: "Critical"
  },
  {
    issueId: "ISS-2024-002", 
    issueType: "Deadlock Detection",
    source: "Transaction Monitor",
    detectedAt: "2024-01-31 14:18:42",
    status: "Analyzing",
    severity: "High"
  },
  {
    issueId: "ISS-2024-003",
    issueType: "Memory Threshold Exceeded",
    source: "Resource Monitor",
    detectedAt: "2024-01-31 14:15:08",
    status: "Resolved",
    severity: "Medium"
  },
  {
    issueId: "ISS-2024-004",
    issueType: "Slow Query Detected",
    source: "Query Analyzer",
    detectedAt: "2024-01-31 14:12:33",
    status: "Active",
    severity: "Low"
  },
  {
    issueId: "ISS-2024-005",
    issueType: "Connection Pool Exhausted",
    source: "Connection Monitor",
    detectedAt: "2024-01-31 14:08:17",
    status: "Investigating",
    severity: "High"
  }
];

// Enhanced column definitions with modern styling
const issueColumns: DataTableColumn<DetectedIssue>[] = [
  {
    key: "issueId",
    header: "Issue ID",
    className: "font-mono text-xs text-slate-600 font-medium"
  },
  {
    key: "issueType", 
    header: "Issue Type",
    className: "font-semibold text-slate-900"
  },
  {
    key: "severity",
    header: "Severity",
    className: "font-medium"
  },
  {
    key: "source",
    header: "Source System",
    className: "text-slate-700"
  },
  {
    key: "detectedAt",
    header: "Detection Time",
    className: "font-mono text-xs text-slate-600"
  },
  {
    key: "status",
    header: "Status",
    className: "font-medium"
  }
];

// Modern Issues Dashboard with sophisticated design
export default function DetectedIssues() {
  return (
    <div className="space-y-8">
      {/* Enhanced page header */}
      <header className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 tracking-tight">
              Detected Issues
            </h1>
            <p className="text-slate-600 mt-2 text-lg">
              Real-time monitoring and anomaly detection across database systems
            </p>
          </div>
          <div className="flex items-center space-x-3">
            <div className="bg-slate-100 px-4 py-2 rounded-lg">
              <span className="text-sm font-medium text-slate-700">
                {mockIssues.length} Total Issues
              </span>
            </div>
            <div className="bg-red-50 px-4 py-2 rounded-lg border border-red-200">
              <span className="text-sm font-medium text-red-700">
                {mockIssues.filter(i => i.status === 'Active').length} Active
              </span>
            </div>
          </div>
        </div>
      </header>

      {/* Stats overview */}
      <div className="grid grid-cols-4 gap-6">
        {[
          { label: "Critical", count: mockIssues.filter(i => i.severity === 'Critical').length, color: "bg-red-50 border-red-200 text-red-700" },
          { label: "High Priority", count: mockIssues.filter(i => i.severity === 'High').length, color: "bg-orange-50 border-orange-200 text-orange-700" },
          { label: "Medium", count: mockIssues.filter(i => i.severity === 'Medium').length, color: "bg-yellow-50 border-yellow-200 text-yellow-700" },
          { label: "Low Priority", count: mockIssues.filter(i => i.severity === 'Low').length, color: "bg-green-50 border-green-200 text-green-700" }
        ].map((stat) => (
          <div key={stat.label} className={`p-6 rounded-xl border ${stat.color}`}>
            <div className="text-2xl font-bold">{stat.count}</div>
            <div className="text-sm font-medium opacity-80">{stat.label}</div>
          </div>
        ))}
      </div>

      {/* Main issues table */}
      <Section
        title="Active Monitoring Feed"
        description="Live stream of detected anomalies, performance issues, and system alerts from database monitoring agents."
      >
        <DataTable 
          columns={issueColumns}
          data={mockIssues}
        />
      </Section>

      {/* Additional insights */}
      <div className="grid grid-cols-2 gap-8">
        <div className="bg-gradient-to-br from-slate-50 to-slate-100 p-6 rounded-xl border border-slate-200">
          <h3 className="font-semibold text-slate-900 mb-3">Detection Sources</h3>
          <div className="space-y-2">
            {Array.from(new Set(mockIssues.map(i => i.source))).map(source => (
              <div key={source} className="flex justify-between items-center">
                <span className="text-sm text-slate-700">{source}</span>
                <span className="text-xs font-medium text-slate-500 bg-white px-2 py-1 rounded">
                  {mockIssues.filter(i => i.source === source).length}
                </span>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-gradient-to-br from-blue-50 to-indigo-50 p-6 rounded-xl border border-blue-200">
          <h3 className="font-semibold text-slate-900 mb-3">System Health</h3>
          <div className="space-y-3">
            <div className="flex items-center space-x-3">
              <div className="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
              <span className="text-sm text-slate-700">Monitoring Active</span>
            </div>
            <div className="flex items-center space-x-3">
              <div className="w-3 h-3 bg-blue-400 rounded-full"></div>
              <span className="text-sm text-slate-700">AI Analysis Running</span>
            </div>
            <div className="flex items-center space-x-3">
              <div className="w-3 h-3 bg-orange-400 rounded-full"></div>
              <span className="text-sm text-slate-700">Healing Actions Pending</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}