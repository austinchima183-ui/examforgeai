import { requireAuth } from '@/lib/auth/require-auth'
import { type ColumnDef } from '@tanstack/react-table'
import { CheckCircle2, XCircle, Trophy, BarChart3, Users, GraduationCap } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Progress } from '@/components/ui/progress'
import { getResultsData } from '@/lib/services/results-service'
import type { ResultListItem } from '@/lib/services/results-service'

export const dynamic = 'force-dynamic'

// ============================================================================
// ExamForge AI — Results Page
// ============================================================================
// Server Component. Requires authentication. Data scoped by role.
// ============================================================================

const statusConfig: Record<string, { variant: 'default' | 'secondary' | 'destructive'; icon: typeof CheckCircle2 }> = {
  passed: { variant: 'default', icon: CheckCircle2 },
  failed: { variant: 'destructive', icon: XCircle },
  absent: { variant: 'secondary', icon: Users },
}

function getScoreColor(percentage: number): string {
  if (percentage >= 80) return 'text-emerald-600'
  if (percentage >= 60) return 'text-amber-600'
  return 'text-red-600'
}

function formatTimeTaken(seconds: number | null): string {
  if (!seconds) return '—'
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  if (h > 0) return `${h}h ${m}m`
  return `${m}m`
}

const columns: ColumnDef<ResultListItem, unknown>[] = [
  {
    accessorKey: 'studentName',
    header: 'Student',
    cell: ({ row }) => {
      const initials = row.original.studentName.split(' ').map((n) => n[0]).join('').slice(0, 2)
      return (
        <div className="flex items-center gap-3">
          <Avatar className="h-8 w-8">
            {row.original.studentAvatarUrl && <AvatarImage src={row.original.studentAvatarUrl} alt={row.original.studentName} />}
            <AvatarFallback className="text-xs bg-primary/10 text-primary">{initials}</AvatarFallback>
          </Avatar>
          <div>
            <p className="font-medium">{row.getValue('studentName')}</p>
            <p className="text-xs text-muted-foreground">{row.original.className ?? row.original.studentEmail}</p>
          </div>
        </div>
      )
    },
  },
  {
    accessorKey: 'examTitle',
    header: 'Exam',
    cell: ({ row }) => (
      <div>
        <p className="font-medium">{row.getValue('examTitle')}</p>
        <p className="text-xs text-muted-foreground">{row.original.subject ?? 'No subject'}</p>
      </div>
    ),
  },
  {
    accessorKey: 'percentage',
    header: 'Score',
    cell: ({ row }) => {
      const pct = row.getValue('percentage') as number
      return (
        <div className="space-y-1">
          <span className={`font-medium ${getScoreColor(pct)}`}>{pct}%</span>
          <p className="text-xs text-muted-foreground">{row.original.score}/{row.original.totalMarks}</p>
        </div>
      )
    },
  },
  {
    accessorKey: 'percentage',
    id: 'performance',
    header: 'Performance',
    cell: ({ row }) => {
      const pct = row.getValue('percentage') as number
      return (<div className="w-24"><Progress value={pct} className="h-2" /></div>)
    },
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const status = row.getValue('status') as string
      const config = statusConfig[status] ?? statusConfig.failed
      return (<Badge variant={config.variant}>{status.charAt(0).toUpperCase() + status.slice(1)}</Badge>)
    },
  },
  {
    id: 'actions',
    header: '',
    cell: () => (<Button variant="ghost" size="sm" className="h-8">View Details</Button>),
  },
]

export default async function ResultsPage() {
  const { user } = await requireAuth()

  // Fetch data scoped by role — students see only their own results
  const data = await getResultsData(user.role, user.id, user.schoolId)

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Results</h1>
          <p className="text-sm text-muted-foreground">View and analyze exam results, scores, and performance data.</p>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard title="Pass Rate" value={`${data.stats.passRate}%`} icon={CheckCircle2} description="Overall pass rate" />
        <StatCard title="Average Score" value={`${data.stats.averageScore}%`} icon={BarChart3} description="Across all exams" />
        <StatCard title="Highest Score" value={`${data.stats.highestScore}%`} icon={Trophy} description="Best result" />
        <StatCard title="Total Submissions" value={data.stats.totalSubmissions} icon={GraduationCap} description="Exam submissions" />
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center"><CheckCircle2 className="h-5 w-5 text-emerald-600" /></div>
            <div><p className="text-2xl font-bold">{data.stats.passedCount}</p><p className="text-xs text-muted-foreground">Passed</p></div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-lg bg-red-100 dark:bg-red-900/30 flex items-center justify-center"><XCircle className="h-5 w-5 text-red-600" /></div>
            <div><p className="text-2xl font-bold">{data.stats.failedCount}</p><p className="text-xs text-muted-foreground">Failed</p></div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-lg bg-gray-100 dark:bg-gray-900/30 flex items-center justify-center"><Users className="h-5 w-5 text-gray-600" /></div>
            <div><p className="text-2xl font-bold">{data.stats.absentCount}</p><p className="text-xs text-muted-foreground">Absent</p></div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Results</CardTitle>
          <CardDescription>Browse and analyze exam results.</CardDescription>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={data.results}
            searchKey="studentName"
            searchPlaceholder="Search results..."
            emptyMessage="No results found"
            emptyDescription="No exam results are available yet. Results will appear once students complete exams."
          />
        </CardContent>
      </Card>
    </div>
  )
}
