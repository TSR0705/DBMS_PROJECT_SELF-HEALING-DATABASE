import { DashboardShell } from "@/components/layout/DashboardShell";

// Dashboard-specific layout wrapper - provides persistent sidebar across all dashboard routes
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <DashboardShell>{children}</DashboardShell>;
}