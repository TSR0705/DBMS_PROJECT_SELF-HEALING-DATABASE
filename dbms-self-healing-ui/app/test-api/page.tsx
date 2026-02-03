'use client';

import { useState } from 'react';
import { apiClient } from '@/lib/api';

export default function TestAPI() {
  const [results, setResults] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState<Record<string, boolean>>({});

  const testEndpoint = async (name: string, testFn: () => Promise<any>) => {
    setLoading(prev => ({ ...prev, [name]: true }));
    try {
      const result = await testFn();
      setResults(prev => ({
        ...prev,
        [name]: {
          status: 'SUCCESS',
          data: result,
          timestamp: new Date().toLocaleTimeString(),
        },
      }));
    } catch (error) {
      setResults(prev => ({
        ...prev,
        [name]: {
          status: 'ERROR',
          error: error instanceof Error ? error.message : String(error),
          timestamp: new Date().toLocaleTimeString(),
        },
      }));
    } finally {
      setLoading(prev => ({ ...prev, [name]: false }));
    }
  };

  const testAll = async () => {
    const tests = [
      { name: 'Health Check', fn: () => apiClient.getHealthCheck() },
      { name: 'Database Health', fn: () => apiClient.getDatabaseHealth() },
      { name: 'Issues', fn: () => apiClient.getDetectedIssues() },
      { name: 'Analysis', fn: () => apiClient.getAllAnalysis() },
      { name: 'Decisions', fn: () => apiClient.getAllDecisions() },
      { name: 'Actions', fn: () => apiClient.getHealingActions() },
      { name: 'Admin Reviews', fn: () => apiClient.getAllAdminReviews() },
      { name: 'Learning History', fn: () => apiClient.getAllLearningHistory() },
    ];

    for (const test of tests) {
      await testEndpoint(test.name, test.fn);
      // Small delay between tests
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  };

  return (
    <div className="p-8 max-w-6xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-slate-900 mb-4">
          End-to-End API Testing
        </h1>
        <p className="text-slate-600 mb-6">
          Comprehensive testing of all backend endpoints with real database data
        </p>

        <div className="flex space-x-4">
          <button
            onClick={testAll}
            disabled={Object.values(loading).some(Boolean)}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed font-semibold"
          >
            {Object.values(loading).some(Boolean)
              ? 'Testing...'
              : 'Test All Endpoints'}
          </button>

          <button
            onClick={() => setResults({})}
            className="px-6 py-3 bg-slate-600 text-white rounded-lg hover:bg-slate-700 font-semibold"
          >
            Clear Results
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {[
          { name: 'Health Check', description: 'Basic API health status' },
          {
            name: 'Database Health',
            description: 'Database connection and stats',
          },
          { name: 'Issues', description: 'Detected database issues' },
          { name: 'Analysis', description: 'AI analysis results' },
          { name: 'Decisions', description: 'System decision log' },
          { name: 'Actions', description: 'Healing actions executed' },
          { name: 'Admin Reviews', description: 'Administrative reviews' },
          { name: 'Learning History', description: 'System learning records' },
        ].map(({ name, description }) => (
          <div
            key={name}
            className="bg-white border border-slate-200 rounded-xl p-6"
          >
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-lg font-semibold text-slate-900">{name}</h3>
                <p className="text-sm text-slate-600">{description}</p>
              </div>
              <button
                onClick={() =>
                  testEndpoint(name, async () => {
                    switch (name) {
                      case 'Health Check':
                        return apiClient.getHealthCheck();
                      case 'Database Health':
                        return apiClient.getDatabaseHealth();
                      case 'Issues':
                        return apiClient.getDetectedIssues();
                      case 'Analysis':
                        return apiClient.getAllAnalysis();
                      case 'Decisions':
                        return apiClient.getAllDecisions();
                      case 'Actions':
                        return apiClient.getHealingActions();
                      case 'Admin Reviews':
                        return apiClient.getAllAdminReviews();
                      case 'Learning History':
                        return apiClient.getAllLearningHistory();
                      default:
                        throw new Error('Unknown test');
                    }
                  })
                }
                disabled={loading[name]}
                className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50 text-sm font-medium"
              >
                {loading[name] ? 'Testing...' : 'Test'}
              </button>
            </div>

            {results[name] && (
              <div className="mt-4">
                <div className="flex items-center space-x-2 mb-2">
                  <div
                    className={`w-3 h-3 rounded-full ${
                      results[name].status === 'SUCCESS'
                        ? 'bg-green-500'
                        : 'bg-red-500'
                    }`}
                  ></div>
                  <span
                    className={`font-semibold ${
                      results[name].status === 'SUCCESS'
                        ? 'text-green-700'
                        : 'text-red-700'
                    }`}
                  >
                    {results[name].status}
                  </span>
                  <span className="text-xs text-slate-500">
                    {results[name].timestamp}
                  </span>
                </div>

                <div className="bg-slate-50 rounded-lg p-4 max-h-64 overflow-y-auto">
                  {results[name].status === 'SUCCESS' ? (
                    <div>
                      <div className="text-sm font-medium text-slate-700 mb-2">
                        Data Summary:
                      </div>
                      {Array.isArray(results[name].data) ? (
                        <div className="text-sm text-slate-600">
                          <div>Count: {results[name].data.length} records</div>
                          {results[name].data.length > 0 && (
                            <div className="mt-2">
                              <div className="font-medium">Sample Record:</div>
                              <pre className="text-xs bg-white p-2 rounded mt-1 overflow-x-auto">
                                {JSON.stringify(results[name].data[0], null, 2)}
                              </pre>
                            </div>
                          )}
                        </div>
                      ) : (
                        <pre className="text-xs text-slate-600 whitespace-pre-wrap">
                          {JSON.stringify(results[name].data, null, 2)}
                        </pre>
                      )}
                    </div>
                  ) : (
                    <div className="text-sm text-red-600">
                      <div className="font-medium">Error:</div>
                      <div>{results[name].error}</div>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        ))}
      </div>

      {/* System Status Summary */}
      <div className="mt-8 bg-slate-50 border border-slate-200 rounded-xl p-6">
        <h2 className="text-xl font-bold text-slate-900 mb-4">
          System Status Summary
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="text-center">
            <div className="text-2xl font-bold text-slate-900">
              {Object.keys(results).length}
            </div>
            <div className="text-sm text-slate-600">Tests Completed</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-green-600">
              {
                Object.values(results).filter(r => r.status === 'SUCCESS')
                  .length
              }
            </div>
            <div className="text-sm text-slate-600">Successful</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-red-600">
              {Object.values(results).filter(r => r.status === 'ERROR').length}
            </div>
            <div className="text-sm text-slate-600">Failed</div>
          </div>
        </div>
      </div>

      {/* Connection Info */}
      <div className="mt-6 text-sm text-slate-500 text-center">
        <p>Backend: http://localhost:8002 | Frontend: http://localhost:3000</p>
        <p>Real-time service updates every 30 seconds</p>
      </div>
    </div>
  );
}
