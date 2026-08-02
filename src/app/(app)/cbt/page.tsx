import { requireAuth } from '@/lib/auth/require-auth'
import { type ColumnDef } from '@tanstack/react-table'
import { FileText, Users, Clock, CheckCircle2, BarChart3 } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ViewButton } from '@/components/buttons/view-button'
import { CreateExamDialog } from '@/components/dialogs/create-exam-dialog'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { getCBTData } from '@/lib/services/cbt-service'
import type { ExamListItem } from '@/lib/services/cbt-service'

export const dynamic = 'force-dynamic'

// ============================================================================
// ExamForge AI — CBT / Exams Page
// ============================================================================
// Server Component. Displays exams from Supabase with real data.
// No mock data. All stats and tables are live.
// ============================================================================

const statusVariantMap: Record<string, 'default' | 'secondary' | 'destructive' | 'outline'> = {
  draft: 'secondary',
  published: 'outline',
  active: 'default',
  completed: 'secondary',
  archived: 'secondary',
  cancelled: 'destructive',
}

const statusLabelMap: Record<string, string> = {
  draft: 'Draft',
  published: 'Upcoming',
  active: 'Active',
  completed: 'Completed',
  archived: 'Archived',
  cancelled: 'Cancelled',
}

function formatDuration(minutes: number): string {
  if (minutes < 60) return `${minutes}m`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return m > 0 ? `${h}h ${m}m` : `${h}h`
}

function formatDate(dateStr: string | null): string {
  if (!dateStr) return '—'
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

const columns: ColumnDef<ExamListItem, unknown>[] = [
  {
    accessorKey: 'title',
    header: 'Exam Title',
    cell: ({ row }) => (
      <div className="flex items-center gap-3">
        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/10">
          <FileText className="h-4 w-4 text-primary" />
        </div>
        <div>
          <p className="font-medium">{row.getValue('title')}</p>
          <p className="text-xs text-muted-foreground">
            {row.original.subject ?? 'No subject'}
            {row.original.className ? ` · ${row.original.className}` : ''}
          </p>
        </div>
      </div>
    ),
  },
  {
    accessorKey: 'duration',
    header: 'Duration',
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <Clock className="h-3.5 w-3.5 text-muted-foreground" />
        {formatDuration(row.getValue('duration'))}
      </div>
    ),
  },
  {
    accessorKey: 'totalQuestions',
    header: 'Questions',
    cell: ({ row }) => (
      <span className="text-sm">{row.getValue('totalQuestions')}</span>
    ),
  },
  {
    accessorKey: 'participants',
    header: 'Participants',
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <Users className="h-3.5 w-3.5 text-muted-foreground" />
        {row.getValue('participants')}
      </div>
    ),
  },
  {
    accessorKey: 'scheduledAt',
    header: 'Scheduled',
    cell: ({ row }) => (
      <span className="text-sm">{formatDate(row.getValue('scheduledAt'))}</span>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const status = row.getValue('status') as string
      return (
        <Badge variant={statusVariantMap[status] ?? 'outline'}>
          {statusLabelMap[status] ?? status}
        </Badge>
      )
    },
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => (
      <div className="flex items-center gap-1">
        <ViewButton href={`/cbt/${row.original.id}`} />
        {row.original.status === 'active' && (
          <ViewButton href={`/cbt/${row.original.id}/monitor`} label="Monitor" />
        )}
      </div>
    ),
  },
]

export default async function CBTPage() {
  const { user } = await requireAuth()
  const role = user.role
  const schoolId = user.schoolId

  // Fetch live data from Supabase
  const data = await getCBTData(role, user.id, schoolId)

  // Filter exams by status for tabs
  const upcomingExams = data.exams.filter(e => e.status === 'published' || e.status === 'draft')
  const activeExams = data.exams.filter(e => e.status === 'active')
  const completedExams = data.exams.filter(e => e.status === 'completed')

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Exams</h1>
          <p className="text-sm text-muted-foreground">
            Manage and monitor computer-based tests and examinations.
          </p>
        </div>
        <CreateExamDialog schoolId={schoolId} />
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Active Exams"
          value={data.stats.activeExams}
          icon={FileText}
          description="Currently running"
        />
        <StatCard
          title="Upcoming Exams"
          value={data.stats.upcomingExams}
          icon={Clock}
          description="Scheduled"
        />
        <StatCard
          title="Completed Exams"
          value={data.stats.completedExams}
          icon={CheckCircle2}
          description="Finished"
        />
        <StatCard
          title="Total Participants"
          value={data.stats.totalParticipants}
          icon={Users}
          description="Across all exams"
        />
      </div>

      {/* Data Table with Tabs */}
      <Card>
        <CardHeader>
          <CardTitle>All Exams</CardTitle>
          <CardDescription>Browse and manage exams on the platform.</CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="all">
            <TabsList className="mb-4">
              <TabsTrigger value="all">All ({data.exams.length})</TabsTrigger>
              <TabsTrigger value="upcoming">Upcoming ({upcomingExams.length})</TabsTrigger>
              <TabsTrigger value="active">Active ({activeExams.length})</TabsTrigger>
              <TabsTrigger value="completed">Completed ({completedExams.length})</TabsTrigger>
            </TabsList>

            <TabsContent value="all">
              <DataTable
                columns={columns}
                data={data.exams}
                searchKey="title"
                searchPlaceholder="Search exams..."
                emptyMessage="No exams found"
                emptyDescription="No exams have been created yet. Create your first exam to get started."
              />
            </TabsContent>

            <TabsContent value="upcoming">
              <DataTable
                columns={columns}
                data={upcomingExams}
                searchKey="title"
                searchPlaceholder="Search upcoming exams..."
                emptyMessage="No upcoming exams"
                emptyDescription="There are no scheduled exams at this time."
              />
            </TabsContent>

            <TabsContent value="active">
              <DataTable
                columns={columns}
                data={activeExams}
                searchKey="title"
                searchPlaceholder="Search active exams..."
                emptyMessage="No active exams"
                emptyDescription="There are no exams currently running."
              />
            </TabsContent>

            <TabsContent value="completed">
              <DataTable
                columns={columns}
                data={completedExams}
                searchKey="title"
                searchPlaceholder="Search completed exams..."
                emptyMessage="No completed exams"
                emptyDescription="No exams have been completed yet."
              />
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  )
}
