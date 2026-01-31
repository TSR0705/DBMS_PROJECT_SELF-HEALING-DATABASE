import { sidebarStructure } from "./sidebar-structure";

// Modern sidebar with sophisticated visual hierarchy and micro-interactions
export function Sidebar() {
  return (
    <aside className="w-72 h-full bg-slate-900 border-r border-slate-800 relative overflow-hidden">
      {/* Subtle gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-b from-slate-800/20 to-transparent" />
      
      {/* Brand area */}
      <div className="relative z-10 p-6 border-b border-slate-800">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-gradient-to-br from-slate-400 to-slate-600 rounded-lg flex items-center justify-center">
            <div className="w-4 h-4 bg-white rounded-sm opacity-90" />
          </div>
          <div>
            <h1 className="text-white font-semibold text-lg">DBMS Console</h1>
            <p className="text-slate-400 text-xs">Self-Healing System</p>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="relative z-10 p-6" aria-label="DBMS self-healing lifecycle navigation">
        {sidebarStructure.map((section, sectionIndex) => (
          <div key={section.title} className={sectionIndex > 0 ? "mt-8" : ""}>
            {/* Enhanced section headers */}
            <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3 px-3">
              {section.title}
            </h3>
            
            <ul className="space-y-1">
              {section.items.map((item) => (
                <li key={item.label}>
                  <div className="group px-3 py-2.5 text-sm font-medium text-slate-300 hover:text-white hover:bg-slate-800/50 rounded-lg cursor-pointer transition-all duration-200 flex items-center space-x-3">
                    {/* Subtle indicator */}
                    <div className="w-1.5 h-1.5 bg-slate-600 group-hover:bg-slate-400 rounded-full transition-colors" />
                    <span>{item.label}</span>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </nav>

      {/* Status indicator */}
      <div className="absolute bottom-6 left-6 right-6">
        <div className="bg-slate-800/50 rounded-lg p-3 border border-slate-700">
          <div className="flex items-center space-x-2">
            <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
            <span className="text-xs text-slate-400">System Active</span>
          </div>
        </div>
      </div>
    </aside>
  );
}