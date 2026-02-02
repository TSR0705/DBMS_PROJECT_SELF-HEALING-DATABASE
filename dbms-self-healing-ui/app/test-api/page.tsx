'use client';

import { useState } from 'react';

export default function TestAPI() {
  const [result, setResult] = useState<string>('');
  const [loading, setLoading] = useState(false);

  const testConnection = async () => {
    setLoading(true);
    setResult('Testing...');
    
    try {
      const response = await fetch('http://localhost:8002/health', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      setResult(`SUCCESS: ${JSON.stringify(data, null, 2)}`);
    } catch (error) {
      setResult(`ERROR: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      setLoading(false);
    }
  };

  const testIssues = async () => {
    setLoading(true);
    setResult('Testing issues endpoint...');
    
    try {
      const response = await fetch('http://localhost:8002/issues/', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      setResult(`SUCCESS: Found ${data.length} issues\n${JSON.stringify(data.slice(0, 2), null, 2)}`);
    } catch (error) {
      setResult(`ERROR: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">API Connection Test</h1>
      
      <div className="space-y-4 mb-6">
        <button
          onClick={testConnection}
          disabled={loading}
          className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
        >
          Test Health Endpoint
        </button>
        
        <button
          onClick={testIssues}
          disabled={loading}
          className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600 disabled:opacity-50 ml-4"
        >
          Test Issues Endpoint
        </button>
      </div>
      
      <div className="bg-gray-100 p-4 rounded">
        <h2 className="font-bold mb-2">Result:</h2>
        <pre className="whitespace-pre-wrap text-sm">{result || 'Click a button to test the API connection'}</pre>
      </div>
      
      <div className="mt-6 text-sm text-gray-600">
        <p>Backend should be running on: http://localhost:8002</p>
        <p>Frontend is running on: http://localhost:3000</p>
      </div>
    </div>
  );
}