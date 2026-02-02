interface StatsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  trend?: 'up' | 'down' | 'neutral';
  className?: string;
}

export function StatsCard({ title, value, subtitle, trend, className = "" }: StatsCardProps) {
  const trendColors = {
    up: 'text-green-600',
    down: 'text-red-600',
    neutral: 'text-slate-600'
  };

  return (
    <div className={`bg-white/90 backdrop-blur-sm rounded-xl p-6 shadow-lg border border-white/20 hover:shadow-xl hover:-translate-y-1 transition-all duration-300 ${className}`}>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-slate-600 mb-1">{title}</p>
          <p className="text-3xl font-bold text-slate-900">{value}</p>
          {subtitle && (
            <p className={`text-sm mt-1 ${trend ? trendColors[trend] : 'text-slate-500'}`}>
              {subtitle}
            </p>
          )}
        </div>
        <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-lg flex items-center justify-center shadow-lg">
          <div className="w-6 h-6 bg-white rounded opacity-80" />
        </div>
      </div>
    </div>
  );
}