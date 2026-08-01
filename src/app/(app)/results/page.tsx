'use client'

import { type ColumnDef } from '@tanstack/react-table'
import { Trophy, Users, TrendingUp, Target, BarChart3, CheckCircle, XCircle } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Progress } from '@/components/ui/progress'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'

// ============================================================================
// ExamForge AI — Results Page
// ============================================================================
// Server Component. Displays a list of exam results with exam filters,
// stats summary, and performance overview.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

type ResultStatus = 'passed' | 'failed' | 'absent'

interface ExamResult {
  id: string
  studentName: string
  studentEmail: string
  examTitle: string
  subject: string
  class: string
  score: number
  totalMarks: number
  percentage: number
  timeTaken: number // minutes
  status: ResultStatus
  submittedAt: string
}

// ──────────────────────────────────────────────────────────────
// Mock Data
// ──────────────────────────────────────────────────────────────

const MOCK_RESULTS: ExamResult[] = [
  {
    id: '1',
    studentName: 'Adebayo Johnson',
    studentEmail: 'adebayo@school.edu',
    examTitle: 'Mathematics Mid-Term Examination',
    subject: 'Mathematics',
    class: 'SS3A',
    score: 85,
    totalMarks: 100,
    percentage: 85,
    timeTaken: 105,
    status: 'passed',
    submittedAt: '2024-01-20T11:00:00Z',
  },
  {
    id: '2',
    studentName: 'Chioma Nwosu',
    studentEmail: 'chioma@school.edu',
    examTitle: 'English Language Mock Exam',
    subject: 'English',
    class: 'SS2B',
    score: 72,
    totalMarks: 80,
    percentage: 90,
    timeTaken: 78,
    status: 'passed',
    submittedAt: '2024-01-18T09:45:00Z',
  },
  {
    id: '3',
    studentName: 'Emeka Okafor',
    studentEmail: 'emeka@school.edu',
    examTitle: 'Mathematics Mid-Term Examination',
    subject: 'Mathematics',
    class: 'SS3A',
    score: 42,
    totalMarks: 100,
    percentage: 42,
    timeTaken: 120,
    status: 'failed',
    submittedAt: '2024-01-20T11:00:00Z',
  },
  {
    id: '4',
    studentName: 'Fatima Abdullahi',
    studentEmail: 'fatima@school.edu',
    examTitle: 'Biology Final Examination',
    subject: 'Biology',
    class: 'SS1C',
    score: 68,
    totalMarks: 100,
    percentage: 68,
    timeTaken: 95,
    status: 'passed',
    submittedAt: '2024-01-15T11:00:00Z',
  },
  {
    id: '5',
    studentName: 'David Adekunle',
    studentEmail: 'david@school.edu',
    examTitle: 'Physics Continuous Assessment',
    subject: 'Physics',
    class: 'SS2A',
    score: 0,
    totalMarks: 60,
    percentage: 0,
    timeTaken: 0,
    status: 'absent',
    submittedAt: '2024-01-28T10:00:00Z',
  },
  {
    id: '6',
    studentName: 'Blessing Okonkwo',
    studentEmail: 'blessing@school.edu',
    examTitle: 'Biology Final Examination',
    subject: 'Biology',
    class: 'SS3B',
    score: 92,
    totalMarks: 100,
    percentage: 92,
    timeTaken: 88,
    status: 'passed',
    submittedAt: '2024-01-15T10:30:00Z',
  },
  {
    id: '7',
    studentName: 'Adebayo Johnson',
    studentEmail: 'adebayo@school.edu',
    examTitle: 'Biology Final Examination',
    subject: 'Biology',
    class: 'SS3A',
    score: 78,
    totalMarks: 100,
    percentage: 78,
    timeTaken: 110,
    status: 'passed',
    submittedAt: '2024-01-15T11:00:00Z',
  },
]

// ──────────────────────────────────────────────────────────────
// Column Definitions
// ──────────────────────────────────────────────────────────────

const statusConfig: Record<ResultStatus, { variant: 'default' | 'destructive' | 'secondary'; label: string }> = {
  passed: { variant: 'default', label: 'Passed' },
  failed: { variant: 'destructive', label: 'Failed' },
  absent: { variant: 'secondary', label: 'Absent' },
}

const columns: ColumnDef<ExamResult, unknown>[] = [
  {
    accessorKey: 'studentName',
    header: 'Student',
    cell: ({ row }) => {
      const initials = row.original.studentName
        .split(' ')
        .map((n) => n[0])
        .join('')
      return (
        <div className="flex items-center gap-3">
          <Avatar className="h-8 w-8">
            <AvatarFallback className="text-xs bg-primary/10 text-primary">
              {initials}
            </AvatarFallback>
          </Avatar>
          <div>
            <p className="font-medium">{row.getValue('studentName')}</p>
            <p className="text-xs text-muted-foreground">{row.original.class}</p>
          </div>
        </div>
      )
    },
  },
  {
    accessorKey: 'examTitle',
    header: 'Exam',
    cell: ({ row }) => (
      <div className="max-w-[200px]">
        <p className="font-medium truncate">{row.getValue('examTitle')}</p>
        <p className="text-xs text-muted-foreground">{row.original.subject}</p>
      </div>
    ),
  },
  {
    accessorKey: 'score',
    header: 'Score',
    cell: ({ row }) => {
      const { score, totalMarks, percentage, status } = row.original
      if (status === 'absent') {
        return <span className="text-sm text-muted-foreground">—</span>
      }
      const color = percentage >= 80 ? 'text-emerald-600' : percentage >= 50 ? 'text-amber-600' : 'text-red-600'
      return (
        <div>
          <span className={`font-medium ${color}`}>{score}/{totalMarks}</span>
          <p className="text-xs text-muted-foreground">{percentage}%</p>
        </div>
      )
    },
  },
  {
    accessorKey: 'percentage',
    header: 'Performance',
    cell: ({ row }) => {
      const percentage = row.original.percentage
      const status = row.original.status
      if (status === 'absent') {
        return <Progress value={0} className="h-2 w-20" />
      }
      return (
        <div className="flex items-center gap-2">
          <Progress
            value={percentage}
            className="h-2 w-20"
          />
          <span className="text-xs text-muted-foreground">{percentage}%</span>
        </div>
      )
    },
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const status = row.getValue('status') as ResultStatus
      const config = statusConfig[status]
      return (
        <Badge variant={config.variant} className="gap-1">
          {status === 'passed' && <CheckCircle className="h-3 w-3" />}
          {status === 'failed' && <XCircle className="h-3 w-3" />}
          {config.label}
        </Badge>
      )
    },
  },
  {
    id: 'actions',
    header: '',
    cell: () => (
      <Button variant="ghost" size="sm" className="h-8">
        View Details
      </Button>
    ),
  },
]

// ──────────────────────────────────────────────────────────────
// Page Component
// ──────────────────────────────────────────────────────────────

export default function ResultsPage() {
  const passedResults = MOCK_RESULTS.filter((r) => r.status === 'passed')
  const failedResults = MOCK_RESULTS.filter((r) => r.status === 'failed')
  const passRate = MOCK_RESULTS.length > 0
    ? ((passedResults.length / (MOCK_RESULTS.length - MOCK_RESULTS.filter((r) => r.status === 'absent').length)) * 100).toFixed(1)
    : '0'
  const avgScore = passedResults.length > 0
    ? (passedResults.reduce((sum, r) => sum + r.percentage, 0) / passedResults.length).toFixed(1)
    : '0'
  const highestScore = passedResults.length > 0
    ? Math.max(...passedResults.map((r) => r.percentage))
    : 0

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Results</h1>
          <p className="text-sm text-muted-foreground">
            View and analyze exam results and student performance.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Select defaultValue="all">
            <SelectTrigger className="h-9 w-[200px]">
              <SelectValue placeholder="Filter by exam" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Exams</SelectItem>
              <SelectItem value="math">Mathematics Mid-Term</SelectItem>
              <SelectItem value="english">English Mock Exam</SelectItem>
              <SelectItem value="biology">Biology Final</SelectItem>
              <SelectItem value="physics">Physics CA</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Stats Summary */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Pass Rate"
          value={`${passRate}%`}
          icon={Trophy}
          trend="up"
          trendValue="+5%"
          description="Overall pass rate"
        />
        <StatCard
          title="Average Score"
          value={`${avgScore}%`}
          icon={BarChart3}
          trend="up"
          trendValue="+3%"
          description="Across all exams"
        />
        <StatCard
          title="Highest Score"
          value={`${highestScore}%`}
          icon={TrendingUp}
          trend="up"
          trendValue="+2%"
          description="Top performer"
        />
        <StatCard
          title="Total Submissions"
          value={MOCK_RESULTS.filter((r) => r.status !== 'absent').length}
          icon={Target}
          trend="up"
          trendValue="+12%"
          description="Completed exams"
        />
      </div>

      {/* Performance Breakdown */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Passed</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-2">
              <CheckCircle className="h-5 w-5 text-emerald-600" />
              <span className="text-2xl font-bold">{passedResults.length}</span>
              <span className="text-sm text-muted-foreground">students</span>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Failed</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-2">
              <XCircle className="h-5 w-5 text-red-600" />
              <span className="text-2xl font-bold">{failedResults.length}</span>
              <span className="text-sm text-muted-foreground">students</span>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Absent</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-2">
              <Users className="h-5 w-5 text-muted-foreground" />
              <span className="text-2xl font-bold">{MOCK_RESULTS.filter((r) => r.status === 'absent').length}</span>
              <span className="text-sm text-muted-foreground">students</span>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Data Table */}
      <Card>
        <CardHeader>
          <CardTitle>All Results</CardTitle>
          <CardDescription>View detailed results for all exam submissions.</CardDescription>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={MOCK_RESULTS}
            searchKey="studentName"
            searchPlaceholder="Search results..."
            emptyMessage="No results found"
            emptyDescription="No exam results match your search criteria."
          />
        </CardContent>
      </Card>
    </div>
  )
}
