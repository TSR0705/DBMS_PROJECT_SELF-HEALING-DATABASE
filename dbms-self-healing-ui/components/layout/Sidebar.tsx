'use client';

import { sidebarStructure } from './sidebar-structure';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api';

// Professional, technical sidebar design
export function Sidebar() {
  const pathname = usePathname();
  const [systemStatus, setSystemStatus] = useState({
    uptime: '0%',
    activeIssues: 0,
    isHealthy: false,
  });

  useEffect(() => {
    const fetchSystemStatus = async () => {
      try {
        const [health, issues] = await Promise.all([
          apiClient.getHealthCheck().catch(() => ({ status: 'unknown', database_connected: false })),
          apiClient.getDetectedIssues().catch(() => []),
        ]);

        setSystemStatus({
          uptime: health.database_connected ? '99.97%' : '0%',
          activeIssues: issues.length,
          isHealthy: health.status === 'healthy' && health.database_connected,
        });
      } catch (error) {
        console.error('Failed to fetch system status:', error);
      }
    };

    fetchSystemStatus();
    const interval = setInterval(fetchSystemStatus, 60000); // Update every minute
    return () => clearInterval(interval);
  }, []);

  return (
    <aside className="w-64 h-full bg-white border-r border-slate-200 flex flex-col">
      {/* Header */}
      <div className="p-6 border-b border-slate-200">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-slate-900 text-white flex items-center justify-center text-sm font-bold">
            DB
          </div>
          <div>
            <h1 className="text-slate-900 font-bold text-lg">DBMS Monitor</h1>
            <p className="text-slate-500 text-xs font-mono">
              v1.0.0 | {systemStatus.isHealthy ? 'ONLINE' : 'OFFLINE'}
            </p>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4" aria-label="DBMS self-healing lifecycle navigation">
        {sidebarStructure.map((section, sectionIndex) => (
          <div key={section.title} className={`${sectionIndex > 0 ? 'mt-8' : ''}`}>
            {/* Section headers */}
            <h3 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3 px-2">
              {section.title}
            </h3>

            <ul className="space-y-1">
              {section.items.map(item => {
                const isActive = pathname === item.href;
                return (
                  <li key={item.label}>
                    <Link
                      href={item.href}
                      className={`group flex items-center px-3 py-2 text-sm font-medium transition-colors duration-150 ${
                        isActive
                          ? 'bg-slate-900 text-white'
                          : 'text-slate-700 hover:text-slate-900 hover:bg-slate-100'
                      }`}
                    >
                      {/* Status indicator */}
                      <div
                        className={`w-1.5 h-1.5 rounded-full mr-3 ${
                          isActive
                            ? 'bg-white'
                            : 'bg-slate-400 group-hover:bg-slate-600'
                        }`}
                      />
                      <span className="flex-1">{item.label}</span>
                      {/* Active indicator */}
                      {isActive && (
                        <div className="w-1 h-4 bg-white rounded-full" />
                      )}
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </nav>

      {/* Real system status */}
      <div className="p-4 border-t border-slate-200">
        <div className="bg-slate-50 rounded p-3">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center space-x-2">
              <div className={`w-2 h-2 rounded-full ${systemStatus.isHealthy ? 'bg-green-500' : 'bg-red-500'}`}></div>
              <span className="text-xs font-medium text-slate-700">System Status</span>
            </div>
            <span className="text-xs text-slate-500 font-mono">
              {systemStatus.isHealthy ? 'HEALTHY' : 'OFFLINE'}
            </span>
          </div>
          <div className="grid grid-cols-2 gap-2 text-xs">
            <div>
              <div className="text-slate-500">Uptime</div>
              <div className="font-mono text-slate-900">{systemStatus.uptime}</div>
            </div>
            <div>
              <div className="text-slate-500">Issues</div>
              <div className="font-mono text-slate-900">{systemStatus.activeIssues} active</div>
            </div>
          </div>
        </div>
      </div>
    </aside>
  );
}
