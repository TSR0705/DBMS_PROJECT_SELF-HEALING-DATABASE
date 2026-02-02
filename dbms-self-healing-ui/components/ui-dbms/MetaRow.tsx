interface MetaRowProps {
  label: string;
  value: string | React.ReactNode;
  className?: string;
}

// Key-value metadata row for displaying structured DBMS information
// Used for issue details, decision summaries, and action execution info
export function MetaRow({ label, value, className = '' }: MetaRowProps) {
  return (
    <div className={`flex items-start gap-lg py-xs ${className}`}>
      <dt className="text-sm font-medium text-gray-700 min-w-32 flex-shrink-0">
        {label}
      </dt>
      <dd className="text-sm text-gray-900 flex-1">{value}</dd>
    </div>
  );
}
