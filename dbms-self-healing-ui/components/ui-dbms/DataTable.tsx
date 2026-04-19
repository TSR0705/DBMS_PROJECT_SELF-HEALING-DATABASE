import * as React from 'react';
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
  render?: (value: T[keyof T], row: T, index: number) => React.ReactNode;
}

// Props for professional DBMS data table component
interface DataTableProps<T> {
  columns: DataTableColumn<T>[];
  data: T[];
  className?: string;
  loading?: boolean;
  expandableRender?: (row: T) => React.ReactNode;
}

// Professional data table with clean, technical design
export function DataTable<T>({
  columns,
  data,
  className = '',
  loading = false,
  expandableRender,
}: DataTableProps<T>) {
  const [expandedRows, setExpandedRows] = React.useState<Record<number, boolean>>(
    {}
  );

  const toggleRow = (index: number) => {
    setExpandedRows(prev => ({
      ...prev,
      [index]: !prev[index],
    }));
  };
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
      className={`bg-white/80 backdrop-blur-xl border border-slate-200/60 shadow-xl shadow-slate-200/40 rounded-2xl overflow-hidden transition-all duration-300 ${className}`}
    >
      {/* Table header */}
      <div className="border-b border-slate-200/60 bg-slate-50/40">
        <Table>
          <TableHeader>
            <TableRow className="border-none hover:bg-transparent">
              {expandableRender && (
                <TableHead className="w-10" />
              )}
              {columns.map(column => (
                <TableHead
                  key={String(column.key)}
                  className={`text-[10px] font-bold text-slate-500 uppercase tracking-widest px-6 py-4 ${column.className || ''}`}
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
                  colSpan={columns.length + (expandableRender ? 1 : 0)}
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
                <React.Fragment key={rowIndex}>
                  <TableRow className="border-b border-slate-100/50 hover:bg-slate-50/50 transition-colors duration-200 group">
                    {expandableRender && (
                      <TableCell className="px-4 py-3">
                        <button
                          onClick={() => toggleRow(rowIndex)}
                          className="text-slate-400 hover:text-slate-600 transition-transform duration-200"
                          style={{
                            transform: expandedRows[rowIndex]
                              ? 'rotate(90deg)'
                              : 'rotate(0deg)',
                          }}
                        >
                          <svg
                            className="w-4 h-4"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={2}
                              d="M9 5l7 7-7 7"
                            />
                          </svg>
                        </button>
                      </TableCell>
                    )}
                    {columns.map(column => {
                    const value = row[column.key];

                    return (
                      <TableCell
                        key={String(column.key)}
                        className={`text-sm px-6 py-4 ${column.className || ''}`}
                      >
                        {column.render
                          ? column.render(value, row, rowIndex)
                          : typeof value === 'object' && value instanceof Date
                            ? value.toLocaleString()
                            : String(value ?? '')}
                      </TableCell>
                    );
                  })}
                  </TableRow>
                  {expandableRender && expandedRows[rowIndex] && (
                    <TableRow className="bg-slate-50/50">
                      <TableCell
                        colSpan={columns.length + 1}
                        className="p-0 border-b border-slate-100"
                      >
                        <div className="px-14 py-4">{expandableRender(row)}</div>
                      </TableCell>
                    </TableRow>
                  )}
                </React.Fragment>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {/* Footer with data count */}
      {data.length > 0 && (
        <div className="bg-transparent border-t border-slate-100/50 px-6 py-3">
          <div className="flex items-center justify-between text-[11px] font-semibold text-slate-400 uppercase tracking-widest">
            <span>
              {data.length} {data.length === 1 ? 'record' : 'records'}
            </span>
            <span className="font-mono bg-slate-50 px-2 py-1 rounded-md border border-slate-100/50">
              Updated: {new Date().toLocaleTimeString()}
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
