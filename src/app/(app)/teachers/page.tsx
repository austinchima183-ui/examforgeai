import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { ROUTES } from '@/lib/constants/routes'
import { type ColumnDef } from '@tanstack/react-table'
import { BookOpen, Plus, Users, GraduationCap, Award } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { getTeachersData } from '@/lib/services/users-service'
import type { TeacherListItem } from '@/lib/services/users-service'

// ============================================================================
// ExamForge AI — Teachers Page
// ============================================================================
// Server Component. Displays teachers from Supabase with real data.
// ============================================================================

const columns: ColumnDef<TeacherListItem, unknown>[] = [
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
            {row.original.avatar_url && <AvatarImage src={row.original.avatar_url} alt={row.original.name} />}
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
    cell: ({ row }) => {
      const dept = row.getValue('department') as string | null
      return dept ? <Badge variant="outline">{dept}</Badge> : <span className="text-muted-foreground text-sm">—</span>
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
          {subjects.map((subject) => (
            <Badge key={subject} variant="secondary" className="text-[10px]">
              {subject}
            </Badge>
          ))}
        </div>
      )
    },
  },
  {
    accessorKey: 'classes',
    header: 'Classes',
    cell: ({ row }) => {
      const classes = row.original.classes
      return <span className="text-sm">{classes?.length ?? 0} classes</span>
    },
  },
  {
    accessorKey: 'exam_count',
    header: 'Exams Created',
    cell: ({ row }) => (
      <span className="text-sm">{row.getValue('exam_count')}</span>
    ),
  },
  {
    accessorKey: 'is_active',
    header: 'Status',
    cell: ({ row }) => {
      const isActive = row.getValue('is_active') as boolean
      return (
        <Badge variant={isActive ? 'default' : 'secondary'}>
          {isActive ? 'Active' : 'Inactive'}
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

export default async function TeachersPage() {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect(ROUTES.LOGIN)
  }

  // Get the user's school_id for school-scoped queries
  const { data: profile } = await supabase
    .from('profiles')
    .select('school_id, role')
    .eq('id', user.id)
    .single()

  const profileData = profile as { school_id: string | null; role: string } | null
  const schoolId = profileData?.role === 'super_admin' ? undefined : profileData?.school_id

  // Fetch real data from Supabase
  const data = await getTeachersData(schoolId)

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
          value={data.total}
          icon={Users}
          description="Registered on platform"
        />
        <StatCard
          title="Active Teachers"
          value={data.activeTeachers}
          icon={BookOpen}
          description="Currently teaching"
        />
        <StatCard
          title="Exams Created"
          value={data.totalExams}
          icon={Award}
          description="Total by all teachers"
        />
        <StatCard
          title="Avg Student Score"
          value={`${data.avgScore}%`}
          icon={GraduationCap}
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
                  <SelectItem value="inactive">Inactive</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={data.teachers}
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
