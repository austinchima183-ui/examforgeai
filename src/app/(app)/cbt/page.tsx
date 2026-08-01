'use client'

import { type ColumnDef } from '@tanstack/react-table'
import { FileText, Plus, Clock, Users, CheckCircle, AlertCircle, Timer } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

// ============================================================================
// ExamForge AI — CBT / Exams Page
// ============================================================================
// Server Component. Displays a list of exams with status filters
// (upcoming, active, completed), create exam button, and data table.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

type ExamStatus = 'draft' | 'upcoming' | 'active' | 'completed' | 'cancelled'

interface Exam {
  id: string
  title: string
  subject: string
  class: string
  duration: number // minutes
  totalQuestions: number
  totalMarks: number
  participants: number
  completedCount: number
  status: ExamStatus
  scheduledAt: string
  createdAt: string
}

// ──────────────────────────────────────────────────────────────
// Mock Data
// ──────────────────────────────────────────────────────────────

const MOCK_EXAMS: Exam[] = [
  {
    id: '1',
    title: 'Mathematics Mid-Term Examination',
    subject: 'Mathematics',
    class: 'SS3A',
    duration: 120,
    totalQuestions: 50,
    totalMarks: 100,
    participants: 45,
    completedCount: 45,
    status: 'completed',
    scheduledAt: '2024-01-20T09:00:00Z',
    createdAt: '2024-01-10T08:00:00Z',
  },
  {
    id: '2',
    title: 'Physics Continuous Assessment',
    subject: 'Physics',
    class: 'SS2A',
    duration: 60,
    totalQuestions: 30,
    totalMarks: 60,
    participants: 38,
    completedCount: 12,
    status: 'active',
    scheduledAt: '2024-01-28T10:00:00Z',
    createdAt: '2024-01-15T14:00:00Z',
  },
  {
    id: '3',
    title: 'English Language Mock Exam',
    subject: 'English',
    class: 'SS3B',
    duration: 90,
    totalQuestions: 40,
    totalMarks: 80,
    participants: 42,
    completedCount: 0,
    status: 'upcoming',
    scheduledAt: '2024-02-05T08:00:00Z',
    createdAt: '2024-01-20T10:00:00Z',
  },
  {
    id: '4',
    title: 'Chemistry Practical Assessment',
    subject: 'Chemistry',
    class: 'SS2B',
    duration: 45,
    totalQuestions: 20,
    totalMarks: 40,
    participants: 35,
    completedCount: 0,
    status: 'draft',
    scheduledAt: '2024-02-10T11:00:00Z',
    createdAt: '2024-01-25T09:00:00Z',
  },
  {
    id: '5',
    title: 'Biology Final Examination',
    subject: 'Biology',
    class: 'SS3A',
    duration: 120,
    totalQuestions: 60,
    totalMarks: 100,
    participants: 45,
    completedCount: 45,
    status: 'completed',
    scheduledAt: '2024-01-15T09:00:00Z',
    createdAt: '2024-01-05T08:00:00Z',
  },
  {
    id: '6',
    title: 'Economics Quiz',
    subject: 'Economics',
    class: 'SS1A',
    duration: 30,
    totalQuestions: 15,
    totalMarks: 30,
    participants: 40,
    completedCount: 0,
    status: 'cancelled',
    scheduledAt: '2024-01-22T14:00:00Z',
    createdAt: '2024-01-18T10:00:00Z',
  },
  {
    id: '7',
    title: 'Government Unit Test',
    subject: 'Government',
    class: 'SS1C',
    duration: 45,
    totalQuestions: 25,
    totalMarks: 50,
    participants: 38,
    completedCount: 0,
    status: 'upcoming',
    scheduledAt: '2024-02-01T10:00:00Z',
    createdAt: '2024-01-22T08:00:00Z',
  },
]

// ──────────────────────────────────────────────────────────────
// Column Definitions
// ──────────────────────────────────────────────────────────────

const statusConfig: Record<ExamStatus, { variant: 'default' | 'secondary' | 'destructive' | 'outline'; label: string }> = {
  draft: { variant: 'outline', label: 'Draft' },
  upcoming: { variant: 'secondary', label: 'Upcoming' },
  active: { variant: 'default', label: 'Active' },
  completed: { variant: 'secondary', label: 'Completed' },
  cancelled: { variant: 'destructive', label: 'Cancelled' },
}

const columns: ColumnDef<Exam, unknown>[] = [
  {
    accessorKey: 'title',
    header: 'Exam Title',
    cell: ({ row }) => (
      <div>
        <p className="font-medium">{row.getValue('title')}</p>
        <p className="text-xs text-muted-foreground">
          {row.original.subject} • {row.original.class}
        </p>
      </div>
    ),
  },
  {
    accessorKey: 'duration',
    header: 'Duration',
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <Timer className="h-3.5 w-3.5 text-muted-foreground" />
        {row.getValue('duration')} min
      </div>
    ),
  },
  {
    accessorKey: 'totalQuestions',
    header: 'Questions',
    cell: ({ row }) => (
      <span className="text-sm">{row.getValue('totalQuestions')} ({row.original.totalMarks} marks)</span>
    ),
  },
  {
    accessorKey: 'participants',
    header: 'Participants',
    cell: ({ row }) => {
      const { participants, completedCount, status } = row.original
      return (
        <div className="flex items-center gap-1.5 text-sm">
          <Users className="h-3.5 w-3.5 text-muted-foreground" />
          {status === 'completed' || status === 'active'
            ? `${completedCount}/${participants}`
            : participants}
        </div>
      )
    },
  },
  {
    accessorKey: 'scheduledAt',
    header: 'Scheduled',
    cell: ({ row }) => {
      const date = new Date(row.getValue('scheduledAt') as string)
      return (
        <div className="flex items-center gap-1.5 text-sm">
          <Clock className="h-3.5 w-3.5 text-muted-foreground" />
          {date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
        </div>
      )
    },
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const status = row.getValue('status') as ExamStatus
      const config = statusConfig[status]
      return <Badge variant={config.variant}>{config.label}</Badge>
    },
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => {
      const status = row.original.status
      return (
        <div className="flex items-center gap-1">
          <Button variant="ghost" size="sm" className="h-8">
            View
          </Button>
          {status === 'active' && (
            <Button variant="ghost" size="sm" className="h-8 text-emerald-600">
              Monitor
            </Button>
          )}
        </div>
      )
    },
  },
]

// ──────────────────────────────────────────────────────────────
// Page Component
// ──────────────────────────────────────────────────────────────

export default function CBTPage() {
  const activeExams = MOCK_EXAMS.filter((e) => e.status === 'active').length
  const upcomingExams = MOCK_EXAMS.filter((e) => e.status === 'upcoming').length
  const completedExams = MOCK_EXAMS.filter((e) => e.status === 'completed').length
  const totalParticipants = MOCK_EXAMS.reduce((sum, e) => sum + e.participants, 0)

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">CBT / Exams</h1>
          <p className="text-sm text-muted-foreground">
            Create, manage, and monitor computer-based tests and examinations.
          </p>
        </div>
        <Button className="gap-2">
          <Plus className="h-4 w-4" />
          Create Exam
        </Button>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Active Exams"
          value={activeExams}
          icon={AlertCircle}
          trend="neutral"
          trendValue="Now"
          description="Currently in progress"
        />
        <StatCard
          title="Upcoming Exams"
          value={upcomingExams}
          icon={Clock}
          trend="up"
          trendValue="+3"
          description="Scheduled ahead"
        />
        <StatCard
          title="Completed Exams"
          value={completedExams}
          icon={CheckCircle}
          trend="up"
          trendValue="+12%"
          description="This term"
        />
        <StatCard
          title="Total Participants"
          value={totalParticipants}
          icon={Users}
          trend="up"
          trendValue="+8%"
          description="Across all exams"
        />
      </div>

      {/* Data Table with Tabs */}
      <Card>
        <CardHeader>
          <CardTitle>Exam Management</CardTitle>
          <CardDescription>View and manage all examinations by status.</CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="all" className="space-y-4">
            <TabsList>
              <TabsTrigger value="all">All ({MOCK_EXAMS.length})</TabsTrigger>
              <TabsTrigger value="upcoming">Upcoming ({upcomingExams})</TabsTrigger>
              <TabsTrigger value="active">Active ({activeExams})</TabsTrigger>
              <TabsTrigger value="completed">Completed ({completedExams})</TabsTrigger>
            </TabsList>

            <TabsContent value="all">
              <DataTable
                columns={columns}
                data={MOCK_EXAMS}
                searchKey="title"
                searchPlaceholder="Search exams..."
                emptyMessage="No exams found"
                emptyDescription="No exams match your search criteria. Try creating a new exam."
              />
            </TabsContent>

            <TabsContent value="upcoming">
              <DataTable
                columns={columns}
                data={MOCK_EXAMS.filter((e) => e.status === 'upcoming')}
                searchKey="title"
                searchPlaceholder="Search upcoming exams..."
                emptyMessage="No upcoming exams"
                emptyDescription="No exams are currently scheduled. Create a new exam to get started."
              />
            </TabsContent>

            <TabsContent value="active">
              <DataTable
                columns={columns}
                data={MOCK_EXAMS.filter((e) => e.status === 'active')}
                searchKey="title"
                searchPlaceholder="Search active exams..."
                emptyMessage="No active exams"
                emptyDescription="No exams are currently in progress."
              />
            </TabsContent>

            <TabsContent value="completed">
              <DataTable
                columns={columns}
                data={MOCK_EXAMS.filter((e) => e.status === 'completed')}
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
