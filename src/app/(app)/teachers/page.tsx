import { Suspense } from 'react'
import { requireAuth } from '@/lib/auth/require-auth'
import { type ColumnDef } from '@tanstack/react-table'
import { BookOpen, Users, GraduationCap, Award } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ViewButton } from '@/components/buttons/view-button'
import { AddTeacherDialog } from '@/components/dialogs/add-teacher-dialog'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { FilterSelect } from '@/components/filters/filter-select'
import { getTeachersData } from '@/lib/services/users-service'
import type { TeacherListItem } from '@/lib/services/users-service'

export const dynamic = 'force-dynamic'

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
    cell: ({ row }) => (
      <ViewButton href={`/teachers/${row.original.id}`} />
    ),
  },
]

export default async function TeachersPage({ searchParams }: { searchParams: Promise<{ department?: string; status?: string }> }) {
  const { user } = await requireAuth()
  const schoolId = user.schoolId
  const _filters = await searchParams // Used by FilterSelect client components

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
        <AddTeacherDialog schoolId={schoolId} />
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
            <Suspense fallback={<div className="h-9 w-[300px]" />}>
              <div className="flex items-center gap-2">
                <FilterSelect name="department" placeholder="All Departments" options={[{label:'Science',value:'Science'},{label:'Arts',value:'Arts'},{label:'Commercial',value:'Commercial'}]} className="h-9 w-[160px]" />
                <FilterSelect name="status" placeholder="All Status" options={[{label:'Active',value:'active'},{label:'Inactive',value:'inactive'}]} className="h-9 w-[140px]" />
              </div>
            </Suspense>
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
