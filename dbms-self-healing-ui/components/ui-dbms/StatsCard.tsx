interface StatsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  trend?: 'up' | 'down' | 'neutral';
  className?: string;
}

export function StatsCard({
  title,
  value,
  subtitle,
  trend,
  className = '',
}: StatsCardProps) {
  const trendColors = {
    up: 'text-green-600',
    down: 'text-red-600',
    neutral: 'text-slate-600',
  };

  const trendIcons = {
    up: '↗',
    down: '↘',
    neutral: '→',
  };

  return (
    <div
      className={`bg-white border border-slate-200 p-6 hover:shadow-md transition-shadow duration-200 ${className}`}
    >
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-slate-600 mb-2">{title}</p>
          <p className="text-2xl font-bold text-slate-900 font-mono">{value}</p>
          {subtitle && (
            <div className="flex items-center mt-2">
              {trend && trend !== 'neutral' && (
                <span className={`text-sm mr-1 ${trendColors[trend]}`}>
                  {trendIcons[trend]}
                </span>
              )}
              <p
                className={`text-sm ${trend ? trendColors[trend] : 'text-slate-500'}`}
              >
                {subtitle}
              </p>
            </div>
          )}
        </div>

        {/* Simple status indicator */}
        <div className="w-3 h-3 bg-slate-300 rounded-full"></div>
      </div>
    </div>
  );
}
