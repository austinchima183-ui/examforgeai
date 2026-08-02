import { requireAuth } from '@/lib/auth/require-auth'
import { type ColumnDef } from '@tanstack/react-table'
import { School, Plus, MapPin, Users } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { getSchoolsData } from '@/lib/services/schools-service'
import type { SchoolListItem } from '@/lib/services/schools-service'

export const dynamic = 'force-dynamic'

// ============================================================================
// ExamForge AI — Schools Management Page
// ============================================================================
// Server Component. Requires authentication. Data scoped by role.
// ============================================================================

const statusVariantMap: Record<string, 'default' | 'secondary' | 'destructive'> = {
  active: 'default',
  inactive: 'secondary',
  suspended: 'destructive',
}

const typeLabelMap: Record<string, string> = {
  primary: 'Primary',
  secondary: 'Secondary',
  tertiary: 'Tertiary',
  mixed: 'Mixed',
}

const columns: ColumnDef<SchoolListItem, unknown>[] = [
  {
    accessorKey: 'name',
    header: 'School Name',
    cell: ({ row }) => (
      <div className="flex items-center gap-3">
        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/10">
          <School className="h-4 w-4 text-primary" />
        </div>
        <div>
          <p className="font-medium">{row.getValue('name')}</p>
          <p className="text-xs text-muted-foreground">{row.original.admin_email ?? row.original.code}</p>
        </div>
      </div>
    ),
  },
  {
    accessorKey: 'location',
    header: 'Location',
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <MapPin className="h-3.5 w-3.5 text-muted-foreground" />
        {row.getValue('location') || 'Not specified'}
      </div>
    ),
  },
  {
    accessorKey: 'school_type',
    header: 'Type',
    cell: ({ row }) => {
      const type = row.getValue('school_type') as string | null
      return type ? <Badge variant="outline">{typeLabelMap[type] ?? type}</Badge> : <span className="text-muted-foreground text-sm">—</span>
    },
  },
  {
    accessorKey: 'student_count',
    header: 'Students',
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <Users className="h-3.5 w-3.5 text-muted-foreground" />
        {Number(row.getValue('student_count')).toLocaleString()}
      </div>
    ),
  },
  {
    accessorKey: 'teacher_count',
    header: 'Teachers',
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <Users className="h-3.5 w-3.5 text-muted-foreground" />
        {Number(row.getValue('teacher_count')).toLocaleString()}
      </div>
    ),
  },
  {
    accessorKey: 'is_active',
    header: 'Status',
    cell: ({ row }) => {
      const isActive = row.getValue('is_active') as boolean
      const status = isActive ? 'active' : 'inactive'
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
      <Button variant="ghost" size="sm" className="h-8">View</Button>
    ),
  },
]

export default async function SchoolsPage() {
  const { user } = await requireAuth()

  // Fetch data scoped by role — school_admin sees only their school
  const data = await getSchoolsData(user.role, user.schoolId)

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Schools</h1>
          <p className="text-sm text-muted-foreground">Manage and monitor all registered schools on the platform.</p>
        </div>
        {(user.role === 'super_admin' || user.role === 'school_admin') && (
          <Button className="gap-2"><Plus className="h-4 w-4" />Add School</Button>
        )}
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard title="Total Schools" value={data.total} icon={School} description="Registered on platform" />
        <StatCard title="Active Schools" value={data.activeSchools} icon={School} description="Currently active" />
        <StatCard title="Total Students" value={data.totalStudents.toLocaleString()} icon={Users} description="Across all schools" />
        <StatCard title="Total Teachers" value={data.totalTeachers.toLocaleString()} icon={Users} description="Across all schools" />
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <CardTitle>All Schools</CardTitle>
              <CardDescription>A list of all registered schools and their details.</CardDescription>
            </div>
            <div className="flex items-center gap-2">
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[140px]"><SelectValue placeholder="Filter by type" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Types</SelectItem>
                  <SelectItem value="primary">Primary</SelectItem>
                  <SelectItem value="secondary">Secondary</SelectItem>
                  <SelectItem value="tertiary">Tertiary</SelectItem>
                  <SelectItem value="mixed">Mixed</SelectItem>
                </SelectContent>
              </Select>
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[140px]"><SelectValue placeholder="Filter by status" /></SelectTrigger>
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
            data={data.schools}
            searchKey="name"
            searchPlaceholder="Search schools..."
            emptyMessage="No schools found"
            emptyDescription="No schools match your search criteria. Try adjusting your filters."
          />
        </CardContent>
      </Card>
    </div>
  )
}
