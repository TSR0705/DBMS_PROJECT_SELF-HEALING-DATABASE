import { Sidebar } from './Sidebar';

// Professional dashboard shell with clean, technical design
export function DashboardShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 overflow-auto">
        {/* Clean, professional content area */}
        <div className="h-full">
          <div className="p-6 h-full">
            {children}
          </div>
        </div>
      </main>
    </div>
  );
}
