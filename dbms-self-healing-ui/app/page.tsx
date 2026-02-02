import Link from "next/link";

export default function DashboardHome() {
  return (
    <main className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-4xl">
          <h1 className="text-2xl font-semibold text-gray-900 mb-4">
            DBMS Self-Healing Dashboard
          </h1>
          <p className="text-gray-600 leading-relaxed mb-6">
            AI-assisted database management and observability platform.
            This is the foundation for a production-grade systems dashboard.
          </p>
          
          {/* Navigation to dashboard */}
          <div className="mb-8">
            <Link 
              href="/dashboard"
              className="inline-flex items-center px-4 py-2 bg-gray-900 text-white text-sm font-medium rounded-md hover:bg-gray-800"
            >
              Enter Dashboard
            </Link>
          </div>
          
          {/* Placeholder for future dashboard modules */}
          <div className="mt-8 p-6 bg-white border border-gray-200 rounded-lg">
            <h2 className="text-lg font-medium text-gray-900 mb-2">
              System Status
            </h2>
            <p className="text-sm text-gray-500">
              Dashboard components will be implemented in subsequent phases.
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}