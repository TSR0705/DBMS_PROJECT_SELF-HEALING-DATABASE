// System Overview - Entry point for DBMS self-healing dashboard
// Displays high-level system state, active issues count, and pipeline status
export default function SystemOverview() {
  return (
    <div className="max-w-content-lg">
      <header className="mb-xl">
        <h1 className="text-xl font-semibold text-gray-900 mb-sm">
          System Overview
        </h1>
        <p className="text-sm text-gray-600 leading-relaxed">
          High-level view of database health, active issues, and self-healing pipeline status. 
          Data originates from DBMS monitoring agents, AI analysis engines, and system health checks.
        </p>
      </header>

      <hr className="border-gray-200 mb-xl" />

      <div className="bg-gray-50 border border-gray-200 rounded-lg p-lg">
        <p className="text-sm text-gray-500 text-center">
          Content will be implemented in later phases
        </p>
      </div>
    </div>
  );
}