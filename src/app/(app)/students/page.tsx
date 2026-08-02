import { Suspense } from 'react'
import { requireAuth } from '@/lib/auth/require-auth'
import { type ColumnDef } from '@tanstack/react-table'
import { GraduationCap, Users, BookOpen, Trophy } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { FilterSelect } from '@/components/filters/filter-select'
import { getStudentsData } from '@/lib/services/users-service'
import type { StudentListItem } from '@/lib/services/users-service'
import { AddStudentDialog } from '@/components/dialogs/add-student-dialog'
import { ViewButton } from '@/components/buttons/view-button'

export const dynamic = 'force-dynamic'

// ============================================================================
// ExamForge AI — Students Page
// ============================================================================
// Server Component. Requires authentication. Data scoped by role.
// ============================================================================

const columns: ColumnDef<StudentListItem, unknown>[] = [
  {
    accessorKey: 'name',
    header: 'Student',
    cell: ({ row }) => {
      const initials = row.original.name.split(' ').map((n) => n[0]).join('')
      return (
        <div className="flex items-center gap-3">
          <Avatar className="h-8 w-8">
            {row.original.avatar_url && <AvatarImage src={row.original.avatar_url} alt={row.original.name} />}
            <AvatarFallback className="text-xs bg-primary/10 text-primary">{initials}</AvatarFallback>
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
    accessorKey: 'class_name',
    header: 'Class',
    cell: ({ row }) => {
      const className = row.getValue('class_name') as string | null
      return className ? <Badge variant="outline">{className}</Badge> : <span className="text-muted-foreground text-sm">—</span>
    },
  },
  {
    accessorKey: 'subjects',
    header: 'Subjects',
    cell: ({ row }) => {
      const subjects = row.original.subjects
      if (!subjects || subjects.length === 0) return <span className="text-muted-foreground text-sm">—</span>
      return (
        <div className="flex flex-wrap gap-1">
          {subjects.slice(0, 2).map((subject) => (<Badge key={subject} variant="secondary" className="text-[10px]">{subject}</Badge>))}
          {subjects.length > 2 && (<Badge variant="secondary" className="text-[10px]">+{subjects.length - 2}</Badge>)}
        </div>
      )
    },
  },
  {
    accessorKey: 'avg_score',
    header: 'Avg Score',
    cell: ({ row }) => {
      const score = row.getValue('avg_score') as number
      if (score === 0) return <span className="text-muted-foreground text-sm">—</span>
      const color = score >= 80 ? 'text-emerald-600' : score >= 60 ? 'text-amber-600' : 'text-red-600'
      return <span className={`font-medium ${color}`}>{score}%</span>
    },
  },
  {
    accessorKey: 'exams_completed',
    header: 'Exams Taken',
    cell: ({ row }) => (<span className="text-sm">{row.getValue('exams_completed')}</span>),
  },
  {
    accessorKey: 'is_active',
    header: 'Status',
    cell: ({ row }) => {
      const isActive = row.getValue('is_active') as boolean
      return (<Badge variant={isActive ? 'default' : 'secondary'}>{isActive ? 'Active' : 'Inactive'}</Badge>)
    },
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => (<ViewButton href={`/students/${row.original.id}`} />),
  },
]

export default async function StudentsPage({ searchParams }: { searchParams: Promise<{ class?: string; subject?: string }> }) {
  const { user } = await requireAuth()
  const _filters = await searchParams // Used by FilterSelect client components

  // Fetch data scoped by role — school_admin/teacher see only their school
  const data = await getStudentsData(user.schoolId, user.role)

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Students</h1>
          <p className="text-sm text-muted-foreground">View and manage student records, performance, and enrollment.</p>
        </div>
        <AddStudentDialog schoolId={user.schoolId} />
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard title="Total Students" value={data.total} icon={GraduationCap} description="Enrolled students" />
        <StatCard title="Active Students" value={data.activeStudents} icon={Users} description="Currently active" />
        <StatCard title="Average Score" value={`${data.avgScore}%`} icon={Trophy} description="Across all exams" />
        <StatCard title="Exams Completed" value={data.totalExams} icon={BookOpen} description="Total submissions" />
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <CardTitle>All Students</CardTitle>
              <CardDescription>Browse and manage student records.</CardDescription>
            </div>
            <Suspense fallback={<div className="h-9 w-[300px]" />}>
              <div className="flex items-center gap-2">
                <FilterSelect name="class" placeholder="All Classes" options={[{label:'SS1',value:'SS1'},{label:'SS2',value:'SS2'},{label:'SS3',value:'SS3'}]} className="h-9 w-[140px]" />
                <FilterSelect name="subject" placeholder="All Subjects" options={[{label:'Mathematics',value:'Mathematics'},{label:'English',value:'English'},{label:'Physics',value:'Physics'},{label:'Chemistry',value:'Chemistry'},{label:'Biology',value:'Biology'}]} className="h-9 w-[160px]" />
              </div>
            </Suspense>
          </div>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={data.students}
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
