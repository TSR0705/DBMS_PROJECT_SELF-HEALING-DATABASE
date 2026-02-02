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

// Props for ultra-modern DBMS data table component
interface DataTableProps<T> {
  columns: DataTableColumn<T>[];
  data: T[];
  className?: string;
  loading?: boolean;
}

// Ultra-modern data table with advanced visual effects and animations
export function DataTable<T extends Record<string, any>>({
  columns,
  data,
  className = '',
  loading = false,
}: DataTableProps<T>) {
  if (loading) {
    return (
      <div
        className={`bg-white/80 backdrop-blur-xl rounded-2xl shadow-xl border border-white/20 overflow-hidden ${className}`}
      >
        <div className="p-8">
          <div className="space-y-4">
            {[...Array(5)].map((_, i) => (
              <div
                key={i}
                className="bg-gradient-to-r from-slate-200 via-slate-100 to-slate-200 h-12 rounded-xl animate-pulse"
              ></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      className={`bg-white/80 backdrop-blur-xl rounded-2xl shadow-xl border border-white/20 overflow-hidden ${className}`}
    >
      {/* Enhanced table header */}
      <div className="bg-gradient-to-r from-slate-900/5 via-blue-900/5 to-indigo-900/5 border-b border-slate-200/50">
        <Table>
          <TableHeader>
            <TableRow className="border-none hover:bg-transparent">
              {columns.map((column, index) => (
                <TableHead
                  key={String(column.key)}
                  className={`text-xs font-bold text-slate-700 uppercase tracking-wider px-6 py-5 bg-transparent animate-fade-in ${column.className || ''}`}
                  style={{ animationDelay: `${index * 50}ms` }}
                >
                  <div className="flex items-center space-x-2">
                    <div className="w-1 h-4 bg-gradient-to-b from-blue-500 to-indigo-600 rounded-full"></div>
                    <span>{column.header}</span>
                  </div>
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
        </Table>
      </div>

      {/* Enhanced table body */}
      <div className="max-h-96 overflow-y-auto">
        <Table>
          <TableBody>
            {data.length === 0 ? (
              <TableRow className="hover:bg-transparent">
                <TableCell
                  colSpan={columns.length}
                  className="text-center py-16 bg-transparent"
                >
                  <div className="flex flex-col items-center space-y-4 animate-fade-in">
                    <div className="w-16 h-16 bg-gradient-to-br from-slate-200 to-slate-300 rounded-2xl flex items-center justify-center shadow-lg">
                      <svg
                        className="w-8 h-8 text-slate-400"
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
                      <div className="text-lg font-semibold mb-1">
                        No data available
                      </div>
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
                  className="border-b border-slate-100/50 hover:bg-gradient-to-r hover:from-blue-50/30 hover:to-indigo-50/30 transition-all duration-300 group animate-fade-in"
                  style={{ animationDelay: `${rowIndex * 50}ms` }}
                >
                  {columns.map((column, colIndex) => {
                    const value = row[column.key];
                    const renderedValue = column.render
                      ? column.render(value, row, rowIndex)
                      : value;

                    return (
                      <TableCell
                        key={String(column.key)}
                        className={`text-sm px-6 py-4 group-hover:bg-white/50 transition-all duration-300 ${column.className || ''}`}
                      >
                        <div className="flex items-center space-x-2">
                          {colIndex === 0 && (
                            <div className="w-1 h-6 bg-gradient-to-b from-blue-400 to-indigo-500 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                          )}
                          <div className="flex-1">{renderedValue}</div>
                        </div>
                      </TableCell>
                    );
                  })}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {/* Enhanced footer with data count */}
      {data.length > 0 && (
        <div className="bg-gradient-to-r from-slate-50/80 to-blue-50/80 border-t border-slate-200/50 px-6 py-3">
          <div className="flex items-center justify-between text-xs text-slate-600">
            <div className="flex items-center space-x-2">
              <div className="w-2 h-2 bg-blue-400 rounded-full animate-pulse"></div>
              <span className="font-medium">
                Showing {data.length} {data.length === 1 ? 'record' : 'records'}
              </span>
            </div>
            <div className="text-slate-500">
              Last updated: {new Date().toLocaleTimeString()}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
