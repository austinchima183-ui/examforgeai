'use client'

import { type ColumnDef } from '@tanstack/react-table'
import { GraduationCap, Plus, Users, BookOpen, Trophy } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'

// ============================================================================
// ExamForge AI — Students Page
// ============================================================================
// Server Component. Displays a list of students with filters (class, subject),
// stats overview, and data table.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

interface Student {
  id: string
  name: string
  email: string
  class: string
  subjects: string[]
  avgScore: number
  examsCompleted: number
  status: 'active' | 'inactive' | 'suspended'
  enrolledAt: string
}

// ──────────────────────────────────────────────────────────────
// Mock Data
// ──────────────────────────────────────────────────────────────

const MOCK_STUDENTS: Student[] = [
  {
    id: '1',
    name: 'Adebayo Johnson',
    email: 'adebayo@school.edu',
    class: 'SS3A',
    subjects: ['Mathematics', 'Physics', 'Chemistry'],
    avgScore: 87.5,
    examsCompleted: 12,
    status: 'active',
    enrolledAt: '2023-09-01T08:00:00Z',
  },
  {
    id: '2',
    name: 'Chioma Nwosu',
    email: 'chioma@school.edu',
    class: 'SS2B',
    subjects: ['English', 'Biology', 'Economics'],
    avgScore: 92.3,
    examsCompleted: 15,
    status: 'active',
    enrolledAt: '2023-09-01T08:00:00Z',
  },
  {
    id: '3',
    name: 'Emeka Okafor',
    email: 'emeka@school.edu',
    class: 'SS3A',
    subjects: ['Mathematics', 'Physics', 'Further Mathematics'],
    avgScore: 78.0,
    examsCompleted: 10,
    status: 'active',
    enrolledAt: '2023-09-01T08:00:00Z',
  },
  {
    id: '4',
    name: 'Fatima Abdullahi',
    email: 'fatima@school.edu',
    class: 'SS1C',
    subjects: ['English', 'Government', 'Literature'],
    avgScore: 85.6,
    examsCompleted: 8,
    status: 'active',
    enrolledAt: '2024-01-15T10:00:00Z',
  },
  {
    id: '5',
    name: 'David Adekunle',
    email: 'david@school.edu',
    class: 'SS2A',
    subjects: ['Mathematics', 'Chemistry', 'Biology'],
    avgScore: 65.2,
    examsCompleted: 6,
    status: 'inactive',
    enrolledAt: '2023-09-01T08:00:00Z',
  },
  {
    id: '6',
    name: 'Blessing Okonkwo',
    email: 'blessing@school.edu',
    class: 'SS3B',
    subjects: ['Physics', 'Chemistry', 'Mathematics'],
    avgScore: 94.1,
    examsCompleted: 18,
    status: 'active',
    enrolledAt: '2022-09-01T08:00:00Z',
  },
]

// ──────────────────────────────────────────────────────────────
// Column Definitions
// ──────────────────────────────────────────────────────────────

const statusVariantMap: Record<Student['status'], 'default' | 'secondary' | 'destructive'> = {
  active: 'default',
  inactive: 'secondary',
  suspended: 'destructive',
}

const columns: ColumnDef<Student, unknown>[] = [
  {
    accessorKey: 'name',
    header: 'Student',
    cell: ({ row }) => {
      const initials = row.original.name
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
            <p className="font-medium">{row.getValue('name')}</p>
            <p className="text-xs text-muted-foreground">{row.original.email}</p>
          </div>
        </div>
      )
    },
  },
  {
    accessorKey: 'class',
    header: 'Class',
    cell: ({ row }) => (
      <Badge variant="outline">{row.getValue('class')}</Badge>
    ),
  },
  {
    accessorKey: 'subjects',
    header: 'Subjects',
    cell: ({ row }) => (
      <div className="flex flex-wrap gap-1">
        {row.original.subjects.slice(0, 2).map((subject) => (
          <Badge key={subject} variant="secondary" className="text-[10px]">
            {subject}
          </Badge>
        ))}
        {row.original.subjects.length > 2 && (
          <Badge variant="secondary" className="text-[10px]">
            +{row.original.subjects.length - 2}
          </Badge>
        )}
      </div>
    ),
  },
  {
    accessorKey: 'avgScore',
    header: 'Avg Score',
    cell: ({ row }) => {
      const score = row.getValue('avgScore') as number
      const color = score >= 80 ? 'text-emerald-600' : score >= 60 ? 'text-amber-600' : 'text-red-600'
      return <span className={`font-medium ${color}`}>{score}%</span>
    },
  },
  {
    accessorKey: 'examsCompleted',
    header: 'Exams Taken',
    cell: ({ row }) => (
      <span className="text-sm">{row.getValue('examsCompleted')}</span>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const status = row.getValue('status') as Student['status']
      return (
        <Badge variant={statusVariantMap[status]}>
          {status.charAt(0).toUpperCase() + status.slice(1)}
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

export default function StudentsPage() {
  const activeStudents = MOCK_STUDENTS.filter((s) => s.status === 'active').length
  const avgScore = MOCK_STUDENTS.reduce((sum, s) => sum + s.avgScore, 0) / MOCK_STUDENTS.length
  const totalExams = MOCK_STUDENTS.reduce((sum, s) => sum + s.examsCompleted, 0)

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Students</h1>
          <p className="text-sm text-muted-foreground">
            View and manage student records, performance, and enrollment.
          </p>
        </div>
        <Button className="gap-2">
          <Plus className="h-4 w-4" />
          Add Student
        </Button>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Students"
          value={MOCK_STUDENTS.length}
          icon={GraduationCap}
          trend="up"
          trendValue="+18%"
          description="Enrolled this term"
        />
        <StatCard
          title="Active Students"
          value={activeStudents}
          icon={Users}
          trend="up"
          trendValue="+12%"
          description="Currently active"
        />
        <StatCard
          title="Average Score"
          value={`${avgScore.toFixed(1)}%`}
          icon={Trophy}
          trend="up"
          trendValue="+5%"
          description="Across all exams"
        />
        <StatCard
          title="Exams Completed"
          value={totalExams}
          icon={BookOpen}
          trend="up"
          trendValue="+22%"
          description="Total submissions"
        />
      </div>

      {/* Data Table */}
      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <CardTitle>All Students</CardTitle>
              <CardDescription>Browse and manage student records.</CardDescription>
            </div>
            <div className="flex items-center gap-2">
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[140px]">
                  <SelectValue placeholder="Filter by class" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Classes</SelectItem>
                  <SelectItem value="ss1">SS1</SelectItem>
                  <SelectItem value="ss2">SS2</SelectItem>
                  <SelectItem value="ss3">SS3</SelectItem>
                </SelectContent>
              </Select>
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[160px]">
                  <SelectValue placeholder="Filter by subject" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Subjects</SelectItem>
                  <SelectItem value="math">Mathematics</SelectItem>
                  <SelectItem value="english">English</SelectItem>
                  <SelectItem value="physics">Physics</SelectItem>
                  <SelectItem value="chemistry">Chemistry</SelectItem>
                  <SelectItem value="biology">Biology</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={MOCK_STUDENTS}
            searchKey="name"
            searchPlaceholder="Search students..."
            emptyMessage="No students found"
            emptyDescription="No students match your search criteria. Try adjusting your filters."
          />
        </CardContent>
      </Card>
    </div>
  )
}
