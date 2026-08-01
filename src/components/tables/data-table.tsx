'use client'

import { useState, useMemo, useCallback } from 'react'
import {
  type ColumnDef,
  type SortingState,
  type ColumnFiltersState,
  flexRender,
  getCoreRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  useReactTable,
} from '@tanstack/react-table'
import {
  ArrowUpDown,
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  Search,
  Inbox,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Skeleton } from '@/components/ui/skeleton'

// ============================================================================
// ExamForge AI — Reusable Data Table
// ============================================================================
// Generic typed data table with client-side sorting, pagination, search,
// empty state, and loading skeleton. Uses TanStack Table + shadcn/ui.
// ============================================================================

export interface DataTableProps<TData, TValue> {
  columns: ColumnDef<TData, TValue>[]
  data: TData[]
  searchKey?: string
  searchPlaceholder?: string
  pageSizeOptions?: number[]
  isLoading?: boolean
  emptyMessage?: string
  emptyDescription?: string
  className?: string
}

// ──────────────────────────────────────────────────────────────
// Loading Skeleton
// ──────────────────────────────────────────────────────────────

function TableSkeleton({ columnCount }: { columnCount: number }) {
  return (
    <div className="space-y-3">
      {Array.from({ length: 5 }).map((_, rowIndex) => (
        <div key={rowIndex} className="flex items-center gap-4 px-2">
          {Array.from({ length: columnCount }).map((_, colIndex) => (
            <Skeleton
              key={colIndex}
              className={cn(
                'h-8 rounded',
                colIndex === 0 ? 'w-[180px]' : 'w-[120px]'
              )}
            />
          ))}
        </div>
      ))}
    </div>
  )
}

// ──────────────────────────────────────────────────────────────
// Empty State
// ──────────────────────────────────────────────────────────────

function TableEmpty({
  message = 'No results found',
  description = 'Try adjusting your search or filter criteria.',
}: {
  message?: string
  description?: string
}) {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-muted">
        <Inbox className="h-6 w-6 text-muted-foreground" />
      </div>
      <p className="mt-3 text-sm font-medium text-muted-foreground">{message}</p>
      <p className="mt-1 text-xs text-muted-foreground">{description}</p>
    </div>
  )
}

// ──────────────────────────────────────────────────────────────
// Data Table Component
// ──────────────────────────────────────────────────────────────

export function DataTable<TData, TValue>({
  columns,
  data,
  searchKey,
  searchPlaceholder = 'Search...',
  pageSizeOptions = [10, 20, 30, 50],
  isLoading = false,
  emptyMessage,
  emptyDescription,
  className,
}: DataTableProps<TData, TValue>) {
  const [sorting, setSorting] = useState<SortingState>([])
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([])
  const [globalFilter, setGlobalFilter] = useState('')

  const table = useReactTable({
    data,
    columns,
    state: {
      sorting,
      columnFilters,
      globalFilter,
    },
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onGlobalFilterChange: setGlobalFilter,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    initialState: {
      pagination: {
        pageSize: pageSizeOptions[0],
      },
    },
  })

  // Derive pagination info
  const pageIndex = table.getState().pagination.pageIndex
  const pageSize = table.getState().pagination.pageSize
  const totalRows = table.getFilteredRowModel().rows.length
  const pageCount = table.getPageCount()
  const rowStart = totalRows === 0 ? 0 : pageIndex * pageSize + 1
  const rowEnd = Math.min((pageIndex + 1) * pageSize, totalRows)

  // Handle page size change
  const handlePageSizeChange = useCallback(
    (value: string) => {
      const size = Number(value)
      table.setPageSize(size)
    },
    [table]
  )

  // Check if search is active
  const isSearchActive = searchKey || globalFilter

  return (
    <div className={cn('space-y-4', className)}>
      {/* Toolbar: Search + Page Size */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        {/* Search */}
        {isSearchActive !== undefined && (
          <div className="relative flex-1 max-w-sm">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder={searchPlaceholder}
              value={
                searchKey
                  ? (table.getColumn(searchKey)?.getFilterValue() as string) ?? ''
                  : globalFilter
              }
              onChange={(e) => {
                const value = e.target.value
                if (searchKey) {
                  table.getColumn(searchKey)?.setFilterValue(value)
                } else {
                  setGlobalFilter(value)
                }
              }}
              className="pl-9 h-9"
            />
          </div>
        )}

        {/* Page Size Selector */}
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <span>Rows per page</span>
          <Select
            value={String(pageSize)}
            onValueChange={handlePageSizeChange}
          >
            <SelectTrigger className="h-8 w-[70px]" size="sm">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {pageSizeOptions.map((size) => (
                <SelectItem key={size} value={String(size)}>
                  {size}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Table */}
      <div className="rounded-lg border">
        {isLoading ? (
          <TableSkeleton columnCount={columns.length} />
        ) : totalRows === 0 ? (
          <TableEmpty message={emptyMessage} description={emptyDescription} />
        ) : (
          <Table>
            <TableHeader>
              {table.getHeaderGroups().map((headerGroup) => (
                <TableRow key={headerGroup.id}>
                  {headerGroup.headers.map((header) => (
                    <TableHead key={header.id}>
                      {header.isPlaceholder ? null : (
                        <div
                          className={
                            header.column.getCanSort()
                              ? 'flex items-center gap-1 cursor-pointer select-none hover:text-foreground'
                              : undefined
                          }
                          onClick={header.column.getToggleSortingHandler()}
                        >
                          {flexRender(
                            header.column.columnDef.header,
                            header.getContext()
                          )}
                          {header.column.getCanSort() && (
                            <ArrowUpDown className="h-3.5 w-3.5 text-muted-foreground" />
                          )}
                        </div>
                      )}
                    </TableHead>
                  ))}
                </TableRow>
              ))}
            </TableHeader>
            <TableBody>
              {table.getRowModel().rows.map((row) => (
                <TableRow key={row.id} data-state={row.getIsSelected() && 'selected'}>
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </TableCell>
                  ))}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>

      {/* Pagination */}
      {!isLoading && totalRows > 0 && (
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-muted-foreground">
            Showing <span className="font-medium">{rowStart}</span>–
            <span className="font-medium">{rowEnd}</span> of{' '}
            <span className="font-medium">{totalRows}</span> results
          </p>
          <div className="flex items-center gap-1">
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => table.setPageIndex(0)}
              disabled={!table.getCanPreviousPage()}
              aria-label="First page"
            >
              <ChevronsLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => table.previousPage()}
              disabled={!table.getCanPreviousPage()}
              aria-label="Previous page"
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <span className="px-2 text-sm text-muted-foreground">
              Page {pageIndex + 1} of {pageCount}
            </span>
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => table.nextPage()}
              disabled={!table.getCanNextPage()}
              aria-label="Next page"
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => table.setPageIndex(pageCount - 1)}
              disabled={!table.getCanNextPage()}
              aria-label="Last page"
            >
              <ChevronsRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}
