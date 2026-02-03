import { DashboardShell } from '@/components/layout/DashboardShell';
import { ErrorBoundary } from '@/components/ui-dbms/ErrorBoundary';

// Dashboard-specific layout wrapper - provides persistent sidebar across all dashboard routes
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-slate-50">
      <ErrorBoundary>
        <DashboardShell>{children}</DashboardShell>
      </ErrorBoundary>
    </div>
  );
}
