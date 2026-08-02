'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Badge } from '@/components/ui/badge'
import { DataTable } from '@/components/tables/data-table'
import { BarChart } from '@/components/charts/bar-chart'
import { type ColumnDef } from '@tanstack/react-table'
import {
  FileSpreadsheet,
  Download,
  Loader2,
  AlertCircle,
  School,
  BookOpen,
  GraduationCap,
  DollarSign,
  Calendar,
} from 'lucide-react'
import type { SchoolReport, TeacherReport, StudentReport, RevenueReport } from '@/lib/services/reports-service'

// ============================================================================
// ExamForge AI — Reports Page
// ============================================================================
// Client component with live Supabase data. Export CSV/Excel/PDF.
// ============================================================================

export default function ReportsPage() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [schoolReports, setSchoolReports] = useState<SchoolReport[]>([])
  const [teacherReports, setTeacherReports] = useState<TeacherReport[]>([])
  const [studentReports, setStudentReports] = useState<StudentReport[]>([])
  const [revenueReport, setRevenueReport] = useState<RevenueReport | null>(null)
  const [dateFrom, setDateFrom] = useState<string>('')
  const [dateTo, setDateTo] = useState<string>('')

  useEffect(() => {
    fetchReports()
  }, [])

  async function fetchReports() {
    setLoading(true)
    setError(null)

    try {
      const params = new URLSearchParams()
      if (dateFrom) params.set('from', dateFrom)
      if (dateTo) params.set('to', dateTo)

      const res = await fetch(`/api/reports?${params.toString()}`)
      if (!res.ok) throw new Error('Failed to fetch reports')
      const data = await res.json()

      setSchoolReports(data.schoolReports ?? [])
      setTeacherReports(data.teacherReports ?? [])
      setStudentReports(data.studentReports ?? [])
      setRevenueReport(data.revenueReport ?? null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load reports')
    } finally {
      setLoading(false)
    }
  }

  function exportCSV(data: Record<string, unknown>[], filename: string) {
    if (data.length === 0) return
    const headers = Object.keys(data[0])
    const csv = [
      headers.join(','),
      ...data.map(row => headers.map(h => JSON.stringify(row[h] ?? '')).join(',')),
    ].join('\n')

    const blob = new Blob([csv], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${filename}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }

  const schoolColumns: ColumnDef<SchoolReport, unknown>[] = [
    { accessorKey: 'schoolName', header: 'School' },
    { accessorKey: 'totalStudents', header: 'Students' },
    { accessorKey: 'totalTeachers', header: 'Teachers' },
    { accessorKey: 'totalExams', header: 'Exams' },
    { accessorKey: 'avgScore', header: 'Avg Score', cell: ({ row }) => <span>{row.getValue('avgScore')}%</span> },
    { accessorKey: 'passRate', header: 'Pass Rate', cell: ({ row }) => <span>{row.getValue('passRate')}%</span> },
    { accessorKey: 'revenue', header: 'Revenue', cell: ({ row }) => <span>₦{(row.getValue('revenue') as number).toLocaleString()}</span> },
  ]

  const teacherColumns: ColumnDef<TeacherReport, unknown>[] = [
    { accessorKey: 'teacherName', header: 'Teacher' },
    { accessorKey: 'examsCreated', header: 'Exams Created' },
    { accessorKey: 'questionsCreated', header: 'Questions Created' },
    { accessorKey: 'totalStudents', header: 'Students' },
  ]

  const studentColumns: ColumnDef<StudentReport, unknown>[] = [
    { accessorKey: 'studentName', header: 'Student' },
    { accessorKey: 'email', header: 'Email' },
    { accessorKey: 'examsCompleted', header: 'Exams' },
    { accessorKey: 'avgScore', header: 'Avg Score', cell: ({ row }) => <span>{row.getValue('avgScore')}%</span> },
    { accessorKey: 'highestScore', header: 'Highest', cell: ({ row }) => <span>{row.getValue('highestScore')}%</span> },
    { accessorKey: 'passRate', header: 'Pass Rate', cell: ({ row }) => <span>{row.getValue('passRate')}%</span> },
  ]

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-center p-12">
          <div className="flex flex-col items-center gap-3">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
            <p className="text-sm text-muted-foreground">Generating reports...</p>
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="space-y-6">
        <Card className="border-destructive/50">
          <CardContent className="p-8 text-center">
            <div className="flex justify-center mb-4">
              <div className="h-16 w-16 rounded-full bg-destructive/10 flex items-center justify-center">
                <AlertCircle className="h-8 w-8 text-destructive" />
              </div>
            </div>
            <h3 className="text-lg font-medium">Failed to generate reports</h3>
            <p className="text-sm text-muted-foreground mt-1">{error}</p>
            <Button variant="outline" className="mt-4" onClick={fetchReports}>Try Again</Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Reports</h1>
          <p className="text-sm text-muted-foreground">
            Generate and export detailed reports across your platform.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <input
            type="date"
            value={dateFrom}
            onChange={(e) => setDateFrom(e.target.value)}
            className="h-9 rounded-md border px-3 text-sm"
            placeholder="From"
          />
          <input
            type="date"
            value={dateTo}
            onChange={(e) => setDateTo(e.target.value)}
            className="h-9 rounded-md border px-3 text-sm"
            placeholder="To"
          />
          <Button variant="outline" size="sm" onClick={fetchReports}>
            <Calendar className="h-4 w-4 mr-1" />
            Apply
          </Button>
        </div>
      </div>

      {/* Revenue Summary */}
      {revenueReport && (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>Revenue Summary</CardTitle>
                <CardDescription>{revenueReport.period}</CardDescription>
              </div>
              <DollarSign className="h-5 w-5 text-muted-foreground" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <div className="p-3 rounded-lg bg-emerald-50 dark:bg-emerald-950/20">
                <p className="text-xs text-muted-foreground">Total Revenue</p>
                <p className="text-xl font-bold">₦{revenueReport.totalRevenue.toLocaleString()}</p>
              </div>
              <div className="p-3 rounded-lg bg-blue-50 dark:bg-blue-950/20">
                <p className="text-xs text-muted-foreground">Total Payments</p>
                <p className="text-xl font-bold">{revenueReport.totalPayments}</p>
              </div>
              <div className="p-3 rounded-lg bg-amber-50 dark:bg-amber-950/20">
                <p className="text-xs text-muted-foreground">Successful</p>
                <p className="text-xl font-bold">{revenueReport.successfulPayments}</p>
              </div>
              <div className="p-3 rounded-lg bg-red-50 dark:bg-red-950/20">
                <p className="text-xs text-muted-foreground">Failed</p>
                <p className="text-xl font-bold">{revenueReport.failedPayments}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Report Tabs */}
      <Tabs defaultValue="schools">
        <TabsList>
          <TabsTrigger value="schools" className="gap-2">
            <School className="h-4 w-4" />
            Schools
          </TabsTrigger>
          <TabsTrigger value="teachers" className="gap-2">
            <BookOpen className="h-4 w-4" />
            Teachers
          </TabsTrigger>
          <TabsTrigger value="students" className="gap-2">
            <GraduationCap className="h-4 w-4" />
            Students
          </TabsTrigger>
        </TabsList>

        <TabsContent value="schools" className="mt-4 space-y-4">
          <div className="flex justify-end">
            <Button variant="outline" size="sm" onClick={() => exportCSV(schoolReports as unknown as Record<string, unknown>[], 'school-reports')}>
              <FileSpreadsheet className="h-4 w-4 mr-1" />
              Export CSV
            </Button>
          </div>
          <DataTable
            columns={schoolColumns}
            data={schoolReports}
            searchKey="schoolName"
            searchPlaceholder="Search schools..."
            emptyMessage="No school reports"
            emptyDescription="No school data available for the selected period."
          />
        </TabsContent>

        <TabsContent value="teachers" className="mt-4 space-y-4">
          <div className="flex justify-end">
            <Button variant="outline" size="sm" onClick={() => exportCSV(teacherReports as unknown as Record<string, unknown>[], 'teacher-reports')}>
              <FileSpreadsheet className="h-4 w-4 mr-1" />
              Export CSV
            </Button>
          </div>
          <DataTable
            columns={teacherColumns}
            data={teacherReports}
            searchKey="teacherName"
            searchPlaceholder="Search teachers..."
            emptyMessage="No teacher reports"
            emptyDescription="No teacher data available for the selected period."
          />
        </TabsContent>

        <TabsContent value="students" className="mt-4 space-y-4">
          <div className="flex justify-end">
            <Button variant="outline" size="sm" onClick={() => exportCSV(studentReports as unknown as Record<string, unknown>[], 'student-reports')}>
              <FileSpreadsheet className="h-4 w-4 mr-1" />
              Export CSV
            </Button>
          </div>
          <DataTable
            columns={studentColumns}
            data={studentReports}
            searchKey="studentName"
            searchPlaceholder="Search students..."
            emptyMessage="No student reports"
            emptyDescription="No student data available for the selected period."
          />
        </TabsContent>
      </Tabs>
    </div>
  )
}
