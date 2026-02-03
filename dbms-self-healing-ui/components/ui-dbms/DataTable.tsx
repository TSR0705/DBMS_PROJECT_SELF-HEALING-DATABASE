import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';

// Enhanced column definition for DBMS data tables with render support
export interface DataTableColumn<T> {
  key: keyof T;
  header: string;
  className?: string;
  render?: (value: any, row: T, index: number) => React.ReactNode;
}

// Props for professional DBMS data table component
interface DataTableProps<T> {
  columns: DataTableColumn<T>[];
  data: T[];
  className?: string;
  loading?: boolean;
}

// Professional data table with clean, technical design
export function DataTable<T extends Record<string, any>>({
  columns,
  data,
  className = '',
  loading = false,
}: DataTableProps<T>) {
  if (loading) {
    return (
      <div
        className={`bg-white border border-slate-200 overflow-hidden ${className}`}
      >
        <div className="p-6">
          <div className="space-y-3">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="bg-slate-100 h-10 animate-pulse"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      className={`bg-white border border-slate-200 overflow-hidden ${className}`}
    >
      {/* Table header */}
      <div className="border-b border-slate-200">
        <Table>
          <TableHeader>
            <TableRow className="border-none hover:bg-transparent">
              {columns.map(column => (
                <TableHead
                  key={String(column.key)}
                  className={`text-xs font-semibold text-slate-700 uppercase tracking-wider px-4 py-3 bg-slate-50 ${column.className || ''}`}
                >
                  {column.header}
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
        </Table>
      </div>

      {/* Table body */}
      <div className="max-h-96 overflow-y-auto">
        <Table>
          <TableBody>
            {data.length === 0 ? (
              <TableRow className="hover:bg-transparent">
                <TableCell
                  colSpan={columns.length}
                  className="text-center py-12 bg-transparent"
                >
                  <div className="flex flex-col items-center space-y-3">
                    <div className="w-12 h-12 bg-slate-100 flex items-center justify-center">
                      <svg
                        className="w-6 h-6 text-slate-400"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
                        />
                      </svg>
                    </div>
                    <div className="text-slate-500">
                      <div className="font-medium mb-1">No data available</div>
                      <div className="text-sm">
                        Data will appear here when available
                      </div>
                    </div>
                  </div>
                </TableCell>
              </TableRow>
            ) : (
              data.map((row, rowIndex) => (
                <TableRow
                  key={rowIndex}
                  className="border-b border-slate-100 hover:bg-slate-50 transition-colors duration-150"
                >
                  {columns.map(column => {
                    const value = row[column.key];
                    const renderedValue = column.render
                      ? column.render(value, row, rowIndex)
                      : value;

                    return (
                      <TableCell
                        key={String(column.key)}
                        className={`text-sm px-4 py-3 ${column.className || ''}`}
                      >
                        {renderedValue}
                      </TableCell>
                    );
                  })}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {/* Footer with data count */}
      {data.length > 0 && (
        <div className="bg-slate-50 border-t border-slate-200 px-4 py-2">
          <div className="flex items-center justify-between text-xs text-slate-600">
            <span className="font-medium">
              {data.length} {data.length === 1 ? 'record' : 'records'}
            </span>
            <span className="font-mono">
              Updated: {new Date().toLocaleTimeString()}
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
