import { Sidebar } from "./Sidebar";

// Modern dashboard shell with glassmorphism and sophisticated layouts
export function DashboardShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar />
      <main className="flex-1 overflow-auto relative">
        {/* Modern content container */}
        <div className="p-8 h-full">
          <div className="glass rounded-2xl shadow-2xl border border-white/20 h-full overflow-auto">
            <div className="p-8 h-full">
              {children}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}