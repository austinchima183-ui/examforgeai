'use client'

import { type ColumnDef } from '@tanstack/react-table'
import { BookOpen, Plus, Users, GraduationCap, Award } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'

// ============================================================================
// ExamForge AI — Teachers Page
// ============================================================================
// Server Component. Displays a list of teachers with filters,
// stats overview, and data table.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

interface Teacher {
  id: string
  name: string
  email: string
  department: string
  subjects: string[]
  classes: string[]
  examCount: number
  avgStudentScore: number
  status: 'active' | 'on_leave' | 'inactive'
  joinedAt: string
}

// ──────────────────────────────────────────────────────────────
// Mock Data
// ──────────────────────────────────────────────────────────────

const MOCK_TEACHERS: Teacher[] = [
  {
    id: '1',
    name: 'Dr. Akinola Babatunde',
    email: 'akinola@school.edu',
    department: 'Science',
    subjects: ['Physics', 'Further Mathematics'],
    classes: ['SS3A', 'SS3B'],
    examCount: 24,
    avgStudentScore: 82.5,
    status: 'active',
    joinedAt: '2021-09-01T08:00:00Z',
  },
  {
    id: '2',
    name: 'Mrs. Okonkwo Grace',
    email: 'grace@school.edu',
    department: 'Arts',
    subjects: ['English', 'Literature'],
    classes: ['SS2A', 'SS2B', 'SS1A'],
    examCount: 18,
    avgStudentScore: 78.3,
    status: 'active',
    joinedAt: '2020-09-01T08:00:00Z',
  },
  {
    id: '3',
    name: 'Mr. Ibrahim Musa',
    email: 'ibrahim@school.edu',
    department: 'Science',
    subjects: ['Chemistry', 'Biology'],
    classes: ['SS2A', 'SS2B'],
    examCount: 15,
    avgStudentScore: 75.0,
    status: 'active',
    joinedAt: '2022-01-15T10:00:00Z',
  },
  {
    id: '4',
    name: 'Ms. Adeyemi Funke',
    email: 'funke@school.edu',
    department: 'Commercial',
    subjects: ['Economics', 'Accounting'],
    classes: ['SS1A', 'SS1B'],
    examCount: 10,
    avgStudentScore: 88.2,
    status: 'on_leave',
    joinedAt: '2023-03-01T08:00:00Z',
  },
  {
    id: '5',
    name: 'Mr. Chukwuemeka Nnamdi',
    email: 'nnamdi@school.edu',
    department: 'Science',
    subjects: ['Mathematics'],
    classes: ['SS3A', 'SS3B', 'SS2A'],
    examCount: 30,
    avgStudentScore: 71.8,
    status: 'active',
    joinedAt: '2019-09-01T08:00:00Z',
  },
  {
    id: '6',
    name: 'Mrs. Bello Hauwa',
    email: 'hauwa@school.edu',
    department: 'Arts',
    subjects: ['Government', 'History'],
    classes: ['SS1A', 'SS1C'],
    examCount: 8,
    avgStudentScore: 80.5,
    status: 'inactive',
    joinedAt: '2022-09-01T08:00:00Z',
  },
]

// ──────────────────────────────────────────────────────────────
// Column Definitions
// ──────────────────────────────────────────────────────────────

const statusVariantMap: Record<Teacher['status'], 'default' | 'secondary' | 'destructive'> = {
  active: 'default',
  on_leave: 'secondary',
  inactive: 'destructive',
}

const statusLabelMap: Record<Teacher['status'], string> = {
  active: 'Active',
  on_leave: 'On Leave',
  inactive: 'Inactive',
}

const columns: ColumnDef<Teacher, unknown>[] = [
  {
    accessorKey: 'name',
    header: 'Teacher',
    cell: ({ row }) => {
      const initials = row.original.name
        .split(' ')
        .filter((_, i, arr) => i === 0 || i === arr.length - 1)
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
            <p className="font-medium">{row.getValue('name')}</p>
            <p className="text-xs text-muted-foreground">{row.original.email}</p>
          </div>
        </div>
      )
    },
  },
  {
    accessorKey: 'department',
    header: 'Department',
    cell: ({ row }) => (
      <Badge variant="outline">{row.getValue('department')}</Badge>
    ),
  },
  {
    accessorKey: 'subjects',
    header: 'Subjects',
    cell: ({ row }) => (
      <div className="flex flex-wrap gap-1">
        {row.original.subjects.map((subject) => (
          <Badge key={subject} variant="secondary" className="text-[10px]">
            {subject}
          </Badge>
        ))}
      </div>
    ),
  },
  {
    accessorKey: 'classes',
    header: 'Classes',
    cell: ({ row }) => (
      <span className="text-sm">{row.original.classes.length} classes</span>
    ),
  },
  {
    accessorKey: 'examCount',
    header: 'Exams Created',
    cell: ({ row }) => (
      <span className="text-sm">{row.getValue('examCount')}</span>
    ),
  },
  {
    accessorKey: 'avgStudentScore',
    header: 'Avg Score',
    cell: ({ row }) => {
      const score = row.getValue('avgStudentScore') as number
      const color = score >= 80 ? 'text-emerald-600' : score >= 60 ? 'text-amber-600' : 'text-red-600'
      return <span className={`font-medium ${color}`}>{score}%</span>
    },
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const status = row.getValue('status') as Teacher['status']
      return (
        <Badge variant={statusVariantMap[status]}>
          {statusLabelMap[status]}
        </Badge>
      )
    },
  },
  {
    id: 'actions',
    header: '',
    cell: () => (
      <Button variant="ghost" size="sm" className="h-8">
        View
      </Button>
    ),
  },
]

// ──────────────────────────────────────────────────────────────
// Page Component
// ──────────────────────────────────────────────────────────────

export default function TeachersPage() {
  const activeTeachers = MOCK_TEACHERS.filter((t) => t.status === 'active').length
  const totalExams = MOCK_TEACHERS.reduce((sum, t) => sum + t.examCount, 0)
  const avgScore = MOCK_TEACHERS.reduce((sum, t) => sum + t.avgStudentScore, 0) / MOCK_TEACHERS.length

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Teachers</h1>
          <p className="text-sm text-muted-foreground">
            Manage teacher profiles, assignments, and performance metrics.
          </p>
        </div>
        <Button className="gap-2">
          <Plus className="h-4 w-4" />
          Add Teacher
        </Button>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Teachers"
          value={MOCK_TEACHERS.length}
          icon={Users}
          trend="up"
          trendValue="+10%"
          description="Registered on platform"
        />
        <StatCard
          title="Active Teachers"
          value={activeTeachers}
          icon={BookOpen}
          trend="up"
          trendValue="+8%"
          description="Currently teaching"
        />
        <StatCard
          title="Exams Created"
          value={totalExams}
          icon={Award}
          trend="up"
          trendValue="+25%"
          description="Total by all teachers"
        />
        <StatCard
          title="Avg Student Score"
          value={`${avgScore.toFixed(1)}%`}
          icon={GraduationCap}
          trend="up"
          trendValue="+4%"
          description="Across all classes"
        />
      </div>

      {/* Data Table */}
      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <CardTitle>All Teachers</CardTitle>
              <CardDescription>Browse and manage teacher records.</CardDescription>
            </div>
            <div className="flex items-center gap-2">
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[160px]">
                  <SelectValue placeholder="Filter by department" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Departments</SelectItem>
                  <SelectItem value="science">Science</SelectItem>
                  <SelectItem value="arts">Arts</SelectItem>
                  <SelectItem value="commercial">Commercial</SelectItem>
                </SelectContent>
              </Select>
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[140px]">
                  <SelectValue placeholder="Filter by status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status</SelectItem>
                  <SelectItem value="active">Active</SelectItem>
                  <SelectItem value="on_leave">On Leave</SelectItem>
                  <SelectItem value="inactive">Inactive</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={MOCK_TEACHERS}
            searchKey="name"
            searchPlaceholder="Search teachers..."
            emptyMessage="No teachers found"
            emptyDescription="No teachers match your search criteria. Try adjusting your filters."
          />
        </CardContent>
      </Card>
    </div>
  )
}
