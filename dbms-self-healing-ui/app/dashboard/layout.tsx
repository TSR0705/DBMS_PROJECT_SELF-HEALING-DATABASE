import { DashboardShell } from '@/components/layout/DashboardShell';

// Dashboard-specific layout wrapper - provides persistent sidebar across all dashboard routes
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-neutral-50">
      <DashboardShell>{children}</DashboardShell>
    </div>
  );
}
