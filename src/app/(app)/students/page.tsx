import { requireAuth } from '@/lib/auth/require-auth'
import { type ColumnDef } from '@tanstack/react-table'
import { GraduationCap, Plus, Users, BookOpen, Trophy } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { getStudentsData } from '@/lib/services/users-service'
import type { StudentListItem } from '@/lib/services/users-service'

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
    cell: () => (<Button variant="ghost" size="sm" className="h-8">View</Button>),
  },
]

export default async function StudentsPage() {
  const { user } = await requireAuth()

  // Fetch data scoped by role — school_admin/teacher see only their school
  const data = await getStudentsData(user.schoolId, user.role)

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Students</h1>
          <p className="text-sm text-muted-foreground">View and manage student records, performance, and enrollment.</p>
        </div>
        <Button className="gap-2"><Plus className="h-4 w-4" />Add Student</Button>
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
            <div className="flex items-center gap-2">
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[140px]"><SelectValue placeholder="Filter by class" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Classes</SelectItem>
                  <SelectItem value="ss1">SS1</SelectItem>
                  <SelectItem value="ss2">SS2</SelectItem>
                  <SelectItem value="ss3">SS3</SelectItem>
                </SelectContent>
              </Select>
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[160px]"><SelectValue placeholder="Filter by subject" /></SelectTrigger>
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
