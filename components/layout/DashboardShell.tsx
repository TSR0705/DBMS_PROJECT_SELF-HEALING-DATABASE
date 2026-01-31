import { Sidebar } from "./Sidebar";

// Modern dashboard layout shell with sophisticated visual hierarchy
export function DashboardShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-gradient-to-br from-slate-50 to-slate-100">
      <Sidebar />
      <main className="flex-1 overflow-auto relative">
        {/* Subtle overlay for depth */}
        <div className="absolute inset-0 bg-gradient-to-b from-white/50 to-transparent pointer-events-none" />
        
        {/* Content container with enhanced spacing and backdrop */}
        <div className="relative z-10 p-8 max-w-7xl mx-auto">
          <div className="bg-white/80 backdrop-blur-sm rounded-2xl shadow-lg border border-slate-200/50 p-8 min-h-full">
            {children}
          </div>
        </div>
      </main>
    </div>
  );
}