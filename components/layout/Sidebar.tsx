"use client";

import { sidebarStructure } from "./sidebar-structure";
import Link from "next/link";
import { usePathname } from "next/navigation";

// Modern sidebar with glassmorphism and smooth animations
export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-80 h-full glass-dark relative overflow-hidden animate-slide-in">
      {/* Animated background gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-slate-900/90 via-blue-900/80 to-indigo-900/90" />
      <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent" />
      
      {/* Brand area with modern styling */}
      <div className="relative z-10 p-8 border-b border-white/10">
        <div className="flex items-center space-x-4">
          <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg animate-pulse-glow">
            <div className="w-6 h-6 bg-white rounded-md opacity-90" />
          </div>
          <div>
            <h1 className="text-white font-bold text-xl">DBMS Console</h1>
            <p className="text-blue-200 text-sm font-medium">Self-Healing System</p>
          </div>
        </div>
      </div>

      {/* Navigation with modern hover effects */}
      <nav className="relative z-10 p-6" aria-label="DBMS self-healing lifecycle navigation">
        {sidebarStructure.map((section, sectionIndex) => (
          <div key={section.title} className={`${sectionIndex > 0 ? "mt-10" : ""} animate-fade-in`} style={{animationDelay: `${sectionIndex * 0.1}s`}}>
            {/* Enhanced section headers */}
            <h3 className="text-xs font-bold text-blue-300 uppercase tracking-wider mb-4 px-4">
              {section.title}
            </h3>
            
            <ul className="space-y-2">
              {section.items.map((item, itemIndex) => {
                const isActive = pathname === item.href;
                return (
                  <li key={item.label} className="animate-fade-in" style={{animationDelay: `${(sectionIndex * section.items.length + itemIndex) * 0.05}s`}}>
                    <Link 
                      href={item.href}
                      className={`group flex items-center px-4 py-3 text-sm font-medium rounded-xl transition-all duration-300 ${
                        isActive 
                          ? 'bg-gradient-to-r from-blue-500/20 to-indigo-500/20 text-white border border-blue-400/30 shadow-lg' 
                          : 'text-slate-300 hover:text-white hover:bg-white/10'
                      }`}
                    >
                      {/* Modern indicator */}
                      <div className={`w-2 h-2 rounded-full mr-3 transition-all duration-300 ${
                        isActive ? 'bg-blue-400 shadow-lg shadow-blue-400/50' : 'bg-slate-600 group-hover:bg-slate-400'
                      }`} />
                      <span className="flex-1">{item.label}</span>
                      {isActive && (
                        <div className="w-1 h-6 bg-gradient-to-b from-blue-400 to-indigo-500 rounded-full" />
                      )}
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </nav>

      {/* Modern status indicator */}
      <div className="absolute bottom-6 left-6 right-6">
        <div className="glass rounded-xl p-4 border border-white/20">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-3 h-3 status-online rounded-full" />
              <span className="text-sm text-white font-medium">System Online</span>
            </div>
            <div className="text-xs text-blue-200">99.9% uptime</div>
          </div>
        </div>
      </div>
    </aside>
  );
}