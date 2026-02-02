interface StatusBadgeProps {
  status: string;
  variant?: 'default' | 'success' | 'warning' | 'error';
}

export function StatusBadge({ status, variant = 'default' }: StatusBadgeProps) {
  const variants = {
    default: 'bg-slate-100 text-slate-700 border-slate-200',
    success: 'bg-green-100 text-green-700 border-green-200',
    warning: 'bg-yellow-100 text-yellow-700 border-yellow-200',
    error: 'bg-red-100 text-red-700 border-red-200'
  };

  return (
    <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border ${variants[variant]}`}>
      {status}
    </span>
  );
}