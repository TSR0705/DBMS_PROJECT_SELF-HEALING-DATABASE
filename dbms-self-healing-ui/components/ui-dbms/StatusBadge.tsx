interface StatusBadgeProps {
  status: string;
  variant?: 'default' | 'success' | 'warning' | 'error' | 'info' | 'gray';
}

export function StatusBadge({ status, variant }: StatusBadgeProps) {
  // Normalize status and determine variant if not provided
  const normalizedStatus = status?.toUpperCase() || 'UNKNOWN';
  
  let finalVariant = variant;
  if (!finalVariant) {
    if (normalizedStatus === 'COMPLETED' || normalizedStatus === 'SUCCESS' || normalizedStatus === 'RESOLVED' || normalizedStatus === 'APPROVED') finalVariant = 'success';
    else if (normalizedStatus === 'FAILED' || normalizedStatus === 'ERROR' || normalizedStatus === 'REJECTED') finalVariant = 'error';
    else if (normalizedStatus === 'RUNNING' || normalizedStatus === 'HEALING') finalVariant = 'info';
    else if (normalizedStatus === 'QUEUED' || normalizedStatus === 'WAITING' || normalizedStatus === 'PENDING') finalVariant = 'gray';
    else finalVariant = 'default';
  }

  const variants = {
    default: 'bg-slate-100 text-slate-700 border-slate-200',
    success: 'bg-green-100 text-green-700 border-green-200',
    warning: 'bg-yellow-100 text-yellow-700 border-yellow-200',
    error: 'bg-red-100 text-red-700 border-red-200',
    info: 'bg-blue-100 text-blue-700 border-blue-200',
    gray: 'bg-slate-100 text-slate-500 border-slate-200',
  };

  const labelMap: Record<string, string> = {
    'QUEUED': 'Waiting',
    'RUNNING': 'Healing...',
    'COMPLETED': 'Resolved',
    'FAILED': 'Failed',
    'SUCCESS': 'Success',
    'PENDING': 'Pending',
    'APPROVED': 'Approved',
    'REJECTED': 'Rejected'
  };

  const displayLabel = labelMap[normalizedStatus] || normalizedStatus;

  return (
    <span
      className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border shadow-sm ${variants[finalVariant]}`}
    >
      {normalizedStatus === 'RUNNING' && (
        <svg className="animate-spin -ml-1 mr-2 h-3 w-3 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
      )}
      {displayLabel}
    </span>
  );
}
