import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

// Generic column definition for DBMS data tables
export interface DataTableColumn<T> {
  key: keyof T;
  header: string;
  className?: string;
}

// Props for sophisticated DBMS data table component
interface DataTableProps<T> {
  columns: DataTableColumn<T>[];
  data: T[];
  className?: string;
}

// Modern data table with sophisticated visual design for DBMS observability
export function DataTable<T extends Record<string, any>>({
  columns,
  data,
  className = "",
}: DataTableProps<T>) {
  return (
    <div className={`bg-white rounded-xl shadow-lg border border-slate-200/60 overflow-hidden ${className}`}>
      <Table>
        <TableHeader>
          <TableRow className="border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100/50">
            {columns.map((column) => (
              <TableHead
                key={String(column.key)}
                className={`text-xs font-semibold text-slate-700 bg-transparent px-6 py-4 ${column.className || ""}`}
              >
                {column.header}
              </TableHead>
            ))}
          </TableRow>
        </TableHeader>
        <TableBody>
          {data.length === 0 ? (
            <TableRow>
              <TableCell
                colSpan={columns.length}
                className="text-center text-sm text-slate-500 py-12 bg-slate-50/30"
              >
                <div className="flex flex-col items-center space-y-2">
                  <div className="w-12 h-12 bg-slate-200 rounded-full flex items-center justify-center">
                    <div className="w-6 h-6 bg-slate-400 rounded opacity-50" />
                  </div>
                  <p>No data available</p>
                </div>
              </TableCell>
            </TableRow>
          ) : (
            data.map((row, index) => (
              <TableRow
                key={index}
                className="border-b border-slate-100 hover:bg-slate-50/50 transition-colors group"
              >
                {columns.map((column) => (
                  <TableCell
                    key={String(column.key)}
                    className={`text-sm text-slate-900 px-6 py-4 group-hover:text-slate-800 ${column.className || ""}`}
                  >
                    {row[column.key]}
                  </TableCell>
                ))}
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </div>
  );
}