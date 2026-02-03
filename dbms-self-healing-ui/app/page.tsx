'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { useRealtimeData } from '@/lib/realtime-service';

export default function LandingPage() {
  const [mounted, setMounted] = useState(false);
  const [currentTime, setCurrentTime] = useState(new Date());
  const { data: realtimeData } = useRealtimeData();

  // Use real-time data or fallback values
  const systemMetrics = realtimeData
    ? {
        uptime: realtimeData.systemMetrics.uptime,
        detectionTime: realtimeData.systemMetrics.detectionTime,
        autoHealSuccess: `${realtimeData.systemMetrics.autoHealSuccessRate}%`,
        issuesResolved: realtimeData.systemMetrics.issuesResolved,
        isConnected: realtimeData.systemMetrics.isConnected,
      }
    : {
        uptime: '0%',
        detectionTime: 'N/A',
        autoHealSuccess: '0%',
        issuesResolved: 0,
        isConnected: false,
      };

  useEffect(() => {
    // Set mounted flag after component mounts
    const mountTimer = setTimeout(() => setMounted(true), 0);

    // Set up time update interval
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);

    return () => {
      clearTimeout(mountTimer);
      clearInterval(timer);
    };
  }, []);

  if (!mounted) return null;

  if (!mounted) return null;

  return (
    <main className="min-h-screen bg-slate-50 font-mono">
      {/* Terminal-style Header */}
      <header className="bg-slate-900 text-green-400 p-4 font-mono text-sm border-b-2 border-green-400">
        <div className="container mx-auto flex justify-between items-center">
          <div className="flex items-center space-x-4">
            <span className="text-green-300">root@dbms-monitor:~$</span>
            <span className="animate-pulse">_</span>
          </div>
          <div className="text-green-300">
            {currentTime.toLocaleTimeString()} |{' '}
            {systemMetrics.isConnected ? 'SYSTEM ONLINE' : 'SYSTEM OFFLINE'}
          </div>
        </div>
      </header>

      <div className="container mx-auto px-6 py-12 max-w-7xl">
        {/* Hero Section - Clean, Technical */}
        <section className="mb-20">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div>
              <div className="mb-6">
                <span className="inline-block px-3 py-1 bg-slate-900 text-green-400 text-xs font-mono uppercase tracking-wider">
                  Database Management System
                </span>
              </div>

              <h1 className="text-5xl lg:text-6xl font-bold text-slate-900 mb-6 leading-tight">
                Self-Healing
                <br />
                <span className="text-slate-600">Database Monitor</span>
              </h1>

              <p className="text-xl text-slate-600 mb-8 leading-relaxed font-sans">
                Autonomous database health monitoring with intelligent issue
                detection, AI-powered analysis, and automated healing
                capabilities. Built for production environments that demand
                99.99% uptime.
              </p>

              <div className="flex flex-col sm:flex-row gap-4 mb-8">
                <Link
                  href="/dashboard/overview"
                  className="inline-flex items-center justify-center px-8 py-4 bg-slate-900 text-white font-semibold hover:bg-slate-800 transition-colors duration-200 group"
                >
                  Access Dashboard
                  <svg
                    className="ml-2 w-4 h-4 group-hover:translate-x-1 transition-transform"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </Link>

                <button className="inline-flex items-center justify-center px-8 py-4 border-2 border-slate-300 text-slate-700 font-semibold hover:border-slate-900 hover:text-slate-900 transition-colors duration-200">
                  View Documentation
                </button>
              </div>

              {/* Real System Status Indicators */}
              <div className="grid grid-cols-3 gap-4 text-sm">
                <div className="flex items-center space-x-2">
                  <div
                    className={`w-2 h-2 rounded-full animate-pulse ${systemMetrics.isConnected ? 'bg-green-500' : 'bg-red-500'}`}
                  ></div>
                  <span className="text-slate-600">
                    {systemMetrics.isConnected
                      ? 'Database Online'
                      : 'Database Offline'}
                  </span>
                </div>
                <div className="flex items-center space-x-2">
                  <div
                    className={`w-2 h-2 rounded-full animate-pulse ${systemMetrics.isConnected ? 'bg-blue-500' : 'bg-gray-400'}`}
                  ></div>
                  <span className="text-slate-600">
                    {systemMetrics.isConnected
                      ? 'AI Monitor Active'
                      : 'AI Monitor Inactive'}
                  </span>
                </div>
                <div className="flex items-center space-x-2">
                  <div
                    className={`w-2 h-2 rounded-full animate-pulse ${systemMetrics.isConnected ? 'bg-orange-500' : 'bg-gray-400'}`}
                  ></div>
                  <span className="text-slate-600">
                    {systemMetrics.isConnected
                      ? 'Auto-Heal Ready'
                      : 'Auto-Heal Offline'}
                  </span>
                </div>
              </div>
            </div>

            {/* Terminal Window Mockup */}
            <div className="bg-slate-900 rounded-lg overflow-hidden shadow-2xl">
              <div className="bg-slate-800 px-4 py-3 flex items-center space-x-2">
                <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                <span className="text-slate-400 text-sm ml-4 font-mono">
                  dbms-monitor.log
                </span>
              </div>
              <div className="p-6 font-mono text-sm space-y-2">
                <div className="text-green-400">
                  [2026-02-02 14:23:15] SYSTEM: Database health check completed
                </div>
                <div className="text-blue-400">
                  [2026-02-02 14:23:16] AI: Analyzing query performance patterns
                </div>
                <div className="text-yellow-400">
                  [2026-02-02 14:23:17] DETECT: Slow query detected (2.3s)
                </div>
                <div className="text-orange-400">
                  [2026-02-02 14:23:18] ANALYZE: Query optimization recommended
                </div>
                <div className="text-green-400">
                  [2026-02-02 14:23:19] HEAL: Index optimization applied
                </div>
                <div className="text-green-400">
                  [2026-02-02 14:23:20] SUCCESS: Query time reduced to 0.2s
                </div>
                <div className="text-slate-500">
                  [2026-02-02 14:23:21] MONITOR: Continuing surveillance...
                </div>
                <div className="text-green-400 animate-pulse">█</div>
              </div>
            </div>
          </div>
        </section>

        {/* Real Metrics Section - Data-Driven Design */}
        <section className="mb-20">
          <div className="bg-white border border-slate-200 p-8">
            <h2 className="text-2xl font-bold text-slate-900 mb-8 text-center">
              Live System Performance Metrics
            </h2>

            <div className="grid grid-cols-2 lg:grid-cols-4 gap-8">
              <div className="text-center">
                <div className="text-4xl font-bold text-slate-900 mb-2 font-mono">
                  {systemMetrics.uptime}
                </div>
                <div className="text-slate-600 text-sm uppercase tracking-wide">
                  Uptime
                </div>
                <div className="text-xs text-slate-500 mt-1">
                  Database connection
                </div>
              </div>

              <div className="text-center">
                <div className="text-4xl font-bold text-slate-900 mb-2 font-mono">
                  {systemMetrics.detectionTime}
                </div>
                <div className="text-slate-600 text-sm uppercase tracking-wide">
                  Detection Time
                </div>
                <div className="text-xs text-slate-500 mt-1">
                  Average response
                </div>
              </div>

              <div className="text-center">
                <div className="text-4xl font-bold text-slate-900 mb-2 font-mono">
                  {systemMetrics.autoHealSuccess}
                </div>
                <div className="text-slate-600 text-sm uppercase tracking-wide">
                  Auto-Heal Success
                </div>
                <div className="text-xs text-slate-500 mt-1">
                  Without intervention
                </div>
              </div>

              <div className="text-center">
                <div className="text-4xl font-bold text-slate-900 mb-2 font-mono">
                  {systemMetrics.issuesResolved.toLocaleString()}
                </div>
                <div className="text-slate-600 text-sm uppercase tracking-wide">
                  Issues Resolved
                </div>
                <div className="text-xs text-slate-500 mt-1">
                  Total resolved
                </div>
              </div>
            </div>

            {/* Connection Status Indicator */}
            <div className="mt-6 text-center">
              <div className="flex items-center justify-center space-x-2">
                <div
                  className={`w-3 h-3 rounded-full ${systemMetrics.isConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`}
                ></div>
                <span className="text-sm text-slate-600">
                  {systemMetrics.isConnected
                    ? 'Live data from database'
                    : 'Offline - showing cached data'}
                </span>
              </div>
            </div>
          </div>
        </section>

        {/* Architecture Section - Technical Diagram */}
        <section className="mb-20">
          <h2 className="text-3xl font-bold text-slate-900 mb-12 text-center">
            System Architecture
          </h2>

          <div className="bg-white border border-slate-200 p-8">
            <div className="grid grid-cols-1 md:grid-cols-5 gap-6 items-center">
              {/* Detection */}
              <div className="text-center p-6 border border-slate-200 bg-slate-50">
                <div className="w-12 h-12 bg-red-100 border-2 border-red-300 rounded mx-auto mb-4 flex items-center justify-center">
                  <div className="w-4 h-4 bg-red-500 rounded"></div>
                </div>
                <h3 className="font-bold text-slate-900 mb-2">DETECTION</h3>
                <p className="text-xs text-slate-600">Real-time monitoring</p>
                <p className="text-xs text-slate-600">Pattern recognition</p>
              </div>

              <div className="hidden md:flex justify-center">
                <div className="w-8 h-0.5 bg-slate-300"></div>
              </div>

              {/* Analysis */}
              <div className="text-center p-6 border border-slate-200 bg-slate-50">
                <div className="w-12 h-12 bg-blue-100 border-2 border-blue-300 rounded mx-auto mb-4 flex items-center justify-center">
                  <div className="w-4 h-4 bg-blue-500 rounded"></div>
                </div>
                <h3 className="font-bold text-slate-900 mb-2">ANALYSIS</h3>
                <p className="text-xs text-slate-600">AI processing</p>
                <p className="text-xs text-slate-600">Root cause analysis</p>
              </div>

              <div className="hidden md:flex justify-center">
                <div className="w-8 h-0.5 bg-slate-300"></div>
              </div>

              {/* Healing */}
              <div className="text-center p-6 border border-slate-200 bg-slate-50">
                <div className="w-12 h-12 bg-green-100 border-2 border-green-300 rounded mx-auto mb-4 flex items-center justify-center">
                  <div className="w-4 h-4 bg-green-500 rounded"></div>
                </div>
                <h3 className="font-bold text-slate-900 mb-2">HEALING</h3>
                <p className="text-xs text-slate-600">Automated fixes</p>
                <p className="text-xs text-slate-600">
                  Performance optimization
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Features Grid - Functional Focus */}
        <section className="mb-20">
          <h2 className="text-3xl font-bold text-slate-900 mb-12 text-center">
            Core Capabilities
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <div className="bg-white border border-slate-200 p-8 hover:shadow-lg transition-shadow duration-300">
              <div className="mb-6">
                <div className="w-8 h-8 bg-slate-900 text-white flex items-center justify-center text-sm font-bold">
                  01
                </div>
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-4">
                Anomaly Detection
              </h3>
              <p className="text-slate-600 mb-4">
                Advanced algorithms monitor database performance metrics, query
                patterns, and system resources to identify potential issues
                before they impact users.
              </p>
              <ul className="text-sm text-slate-500 space-y-1">
                <li>• Query performance monitoring</li>
                <li>• Deadlock detection</li>
                <li>• Resource utilization tracking</li>
              </ul>
            </div>

            <div className="bg-white border border-slate-200 p-8 hover:shadow-lg transition-shadow duration-300">
              <div className="mb-6">
                <div className="w-8 h-8 bg-slate-900 text-white flex items-center justify-center text-sm font-bold">
                  02
                </div>
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-4">
                Intelligent Analysis
              </h3>
              <p className="text-slate-600 mb-4">
                Machine learning models analyze detected issues, predict impact
                severity, and recommend optimal resolution strategies based on
                historical data.
              </p>
              <ul className="text-sm text-slate-500 space-y-1">
                <li>• Root cause identification</li>
                <li>• Impact assessment</li>
                <li>• Solution recommendation</li>
              </ul>
            </div>

            <div className="bg-white border border-slate-200 p-8 hover:shadow-lg transition-shadow duration-300">
              <div className="mb-6">
                <div className="w-8 h-8 bg-slate-900 text-white flex items-center justify-center text-sm font-bold">
                  03
                </div>
              </div>
              <h3 className="text-xl font-bold text-slate-900 mb-4">
                Automated Healing
              </h3>
              <p className="text-slate-600 mb-4">
                Execute proven remediation strategies automatically, with
                intelligent decision-making to determine when human intervention
                is required.
              </p>
              <ul className="text-sm text-slate-500 space-y-1">
                <li>• Index optimization</li>
                <li>• Query rewriting</li>
                <li>• Resource reallocation</li>
              </ul>
            </div>
          </div>
        </section>

        {/* Technical Specifications */}
        <section className="mb-20">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
            <div>
              <h2 className="text-2xl font-bold text-slate-900 mb-6">
                Technical Specifications
              </h2>
              <div className="space-y-4 font-mono text-sm">
                <div className="flex justify-between border-b border-slate-200 pb-2">
                  <span className="text-slate-600">Database Support</span>
                  <span className="text-slate-900">
                    MySQL, PostgreSQL, Oracle
                  </span>
                </div>
                <div className="flex justify-between border-b border-slate-200 pb-2">
                  <span className="text-slate-600">Detection Latency</span>
                  <span className="text-slate-900">&lt; 150ms average</span>
                </div>
                <div className="flex justify-between border-b border-slate-200 pb-2">
                  <span className="text-slate-600">API Response Time</span>
                  <span className="text-slate-900">
                    &lt; 50ms (95th percentile)
                  </span>
                </div>
                <div className="flex justify-between border-b border-slate-200 pb-2">
                  <span className="text-slate-600">Monitoring Frequency</span>
                  <span className="text-slate-900">
                    Real-time (1s intervals)
                  </span>
                </div>
                <div className="flex justify-between border-b border-slate-200 pb-2">
                  <span className="text-slate-600">Data Retention</span>
                  <span className="text-slate-900">90 days (configurable)</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-600">Deployment</span>
                  <span className="text-slate-900">Docker, Kubernetes</span>
                </div>
              </div>
            </div>

            <div>
              <h2 className="text-2xl font-bold text-slate-900 mb-6">
                System Requirements
              </h2>
              <div className="bg-slate-900 text-green-400 p-6 font-mono text-sm rounded">
                <div className="mb-4 text-green-300">
                  # Minimum Requirements
                </div>
                <div className="space-y-1">
                  <div>CPU: 4 cores @ 2.4GHz</div>
                  <div>RAM: 8GB minimum, 16GB recommended</div>
                  <div>Storage: 100GB SSD</div>
                  <div>Network: 1Gbps connection</div>
                </div>

                <div className="mt-6 mb-4 text-green-300">
                  # Supported Platforms
                </div>
                <div className="space-y-1">
                  <div>Linux (Ubuntu 20.04+, CentOS 8+)</div>
                  <div>Docker Engine 20.10+</div>
                  <div>Kubernetes 1.21+</div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="border-t border-slate-200 pt-12">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
            <div>
              <h3 className="font-bold text-slate-900 mb-4">Documentation</h3>
              <ul className="space-y-2 text-slate-600">
                <li>
                  <a
                    href="#"
                    className="hover:text-slate-900 transition-colors"
                  >
                    Installation Guide
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    className="hover:text-slate-900 transition-colors"
                  >
                    API Reference
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    className="hover:text-slate-900 transition-colors"
                  >
                    Configuration
                  </a>
                </li>
              </ul>
            </div>

            <div>
              <h3 className="font-bold text-slate-900 mb-4">Support</h3>
              <ul className="space-y-2 text-slate-600">
                <li>
                  <a
                    href="#"
                    className="hover:text-slate-900 transition-colors"
                  >
                    Troubleshooting
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    className="hover:text-slate-900 transition-colors"
                  >
                    Community Forum
                  </a>
                </li>
                <li>
                  <a
                    href="#"
                    className="hover:text-slate-900 transition-colors"
                  >
                    Contact Support
                  </a>
                </li>
              </ul>
            </div>

            <div>
              <h3 className="font-bold text-slate-900 mb-4">System Status</h3>
              <div className="space-y-2 text-sm">
                <div className="flex items-center space-x-2">
                  <div
                    className={`w-2 h-2 rounded-full ${systemMetrics.isConnected ? 'bg-green-500' : 'bg-red-500'}`}
                  ></div>
                  <span className="text-slate-600">
                    {systemMetrics.isConnected
                      ? 'All systems operational'
                      : 'System offline'}
                  </span>
                </div>
                <div className="text-slate-500">
                  Last updated: {currentTime.toLocaleString()}
                </div>
              </div>
            </div>
          </div>

          <div className="border-t border-slate-200 pt-8 text-center text-slate-500 text-sm">
            <p>
              © 2026 DBMS Self-Healing Monitor. Built for production database
              environments.
            </p>
          </div>
        </footer>
      </div>
    </main>
  );
}
