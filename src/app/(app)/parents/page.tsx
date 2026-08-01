import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { ROUTES } from '@/lib/constants/routes'
import { type ColumnDef } from '@tanstack/react-table'
import { Users, Plus, Phone, Mail, GraduationCap } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { getParentsData } from '@/lib/services/users-service'
import type { ParentListItem } from '@/lib/services/users-service'

// ============================================================================
// ExamForge AI — Parents Page
// ============================================================================
// Server Component. Displays parents from Supabase with real data.
// ============================================================================

const columns: ColumnDef<ParentListItem, unknown>[] = [
  {
    accessorKey: 'name',
    header: 'Parent',
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
            <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
              <Mail className="h-3 w-3" />
              {row.original.email}
            </div>
          </div>
        </div>
      )
    },
  },
  {
    accessorKey: 'phone',
    header: 'Phone',
    cell: ({ row }) => {
      const phone = row.getValue('phone') as string | null
      return phone ? (
        <div className="flex items-center gap-1.5 text-sm">
          <Phone className="h-3.5 w-3.5 text-muted-foreground" />
          {phone}
        </div>
      ) : <span className="text-muted-foreground text-sm">—</span>
    },
  },
  {
    accessorKey: 'children',
    header: 'Children',
    cell: ({ row }) => {
      const children = row.original.children
      if (!children || children.length === 0) return <span className="text-muted-foreground text-sm">No children linked</span>
      return (
        <div className="space-y-1">
          {children.map((child) => (
            <div key={child.id} className="flex items-center gap-1.5 text-sm">
              <GraduationCap className="h-3 w-3 text-muted-foreground" />
              <span>{child.name}</span>
              {child.class_name && (
                <Badge variant="outline" className="text-[10px] h-4 ml-1">
                  {child.class_name}
                </Badge>
              )}
            </div>
          ))}
        </div>
      )
    },
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

export default async function ParentsPage() {
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
  const data = await getParentsData(schoolId)

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Parents</h1>
          <p className="text-sm text-muted-foreground">
            View and manage parent records and their associated students.
          </p>
        </div>
        <Button className="gap-2">
          <Plus className="h-4 w-4" />
          Add Parent
        </Button>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Parents"
          value={data.total}
          icon={Users}
          description="Registered on platform"
        />
        <StatCard
          title="Active Parents"
          value={data.activeParents}
          icon={Users}
          description="Recently active"
        />
        <StatCard
          title="Linked Students"
          value={data.totalChildren}
          icon={GraduationCap}
          description="Across all parents"
        />
        <StatCard
          title="Avg Children"
          value={data.avgChildrenPerParent}
          icon={Users}
          description="Per parent"
        />
      </div>

      {/* Data Table */}
      <Card>
        <CardHeader>
          <div>
            <CardTitle>All Parents</CardTitle>
            <CardDescription>Browse and manage parent records and student associations.</CardDescription>
          </div>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={data.parents}
            searchKey="name"
            searchPlaceholder="Search parents..."
            emptyMessage="No parents found"
            emptyDescription="No parents match your search criteria. Try adjusting your filters."
          />
        </CardContent>
      </Card>
    </div>
  )
}
