'use client'

import { type ColumnDef } from '@tanstack/react-table'
import { Users, Plus, Phone, Mail, GraduationCap } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'

// ============================================================================
// ExamForge AI — Parents Page
// ============================================================================
// Server Component. Displays a list of parents with student association,
// stats overview, and data table.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

interface ParentStudent {
  id: string
  name: string
  class: string
}

interface Parent {
  id: string
  name: string
  email: string
  phone: string
  students: ParentStudent[]
  status: 'active' | 'inactive'
  lastActiveAt: string
  createdAt: string
}

// ──────────────────────────────────────────────────────────────
// Mock Data
// ──────────────────────────────────────────────────────────────

const MOCK_PARENTS: Parent[] = [
  {
    id: '1',
    name: 'Mr. Johnson Adeyemi',
    email: 'johnson@email.com',
    phone: '+234-801-234-5678',
    students: [
      { id: 's1', name: 'Adebayo Johnson', class: 'SS3A' },
      { id: 's2', name: 'Tolu Johnson', class: 'SS1B' },
    ],
    status: 'active',
    lastActiveAt: '2024-01-28T14:30:00Z',
    createdAt: '2023-09-01T08:00:00Z',
  },
  {
    id: '2',
    name: 'Mrs. Nwosu Adaeze',
    email: 'adaeze@email.com',
    phone: '+234-802-345-6789',
    students: [
      { id: 's3', name: 'Chioma Nwosu', class: 'SS2B' },
    ],
    status: 'active',
    lastActiveAt: '2024-01-27T10:15:00Z',
    createdAt: '2023-09-01T08:00:00Z',
  },
  {
    id: '3',
    name: 'Alhaji Musa Ibrahim',
    email: 'musa@email.com',
    phone: '+234-803-456-7890',
    students: [
      { id: 's4', name: 'Fatima Abdullahi', class: 'SS1C' },
      { id: 's5', name: 'Ahmed Abdullahi', class: 'SS2A' },
      { id: 's6', name: 'Aisha Abdullahi', class: 'JSS3' },
    ],
    status: 'active',
    lastActiveAt: '2024-01-25T09:00:00Z',
    createdAt: '2023-09-01T08:00:00Z',
  },
  {
    id: '4',
    name: 'Mrs. Okafor Ngozi',
    email: 'ngozi@email.com',
    phone: '+234-804-567-8901',
    students: [
      { id: 's7', name: 'Emeka Okafor', class: 'SS3A' },
    ],
    status: 'inactive',
    lastActiveAt: '2023-12-15T16:45:00Z',
    createdAt: '2023-09-01T08:00:00Z',
  },
  {
    id: '5',
    name: 'Mr. Adekunle Peter',
    email: 'peter@email.com',
    phone: '+234-805-678-9012',
    students: [
      { id: 's8', name: 'David Adekunle', class: 'SS2A' },
    ],
    status: 'active',
    lastActiveAt: '2024-01-28T08:30:00Z',
    createdAt: '2023-09-01T08:00:00Z',
  },
]

// ──────────────────────────────────────────────────────────────
// Column Definitions
// ──────────────────────────────────────────────────────────────

const columns: ColumnDef<Parent, unknown>[] = [
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
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <Phone className="h-3.5 w-3.5 text-muted-foreground" />
        {row.getValue('phone')}
      </div>
    ),
  },
  {
    accessorKey: 'students',
    header: 'Children',
    cell: ({ row }) => (
      <div className="space-y-1">
        {row.original.students.map((student) => (
          <div key={student.id} className="flex items-center gap-1.5 text-sm">
            <GraduationCap className="h-3 w-3 text-muted-foreground" />
            <span>{student.name}</span>
            <Badge variant="outline" className="text-[10px] h-4 ml-1">
              {student.class}
            </Badge>
          </div>
        ))}
      </div>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const status = row.getValue('status') as Parent['status']
      return (
        <Badge variant={status === 'active' ? 'default' : 'secondary'}>
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

export default function ParentsPage() {
  const activeParents = MOCK_PARENTS.filter((p) => p.status === 'active').length
  const totalStudents = MOCK_PARENTS.reduce((sum, p) => sum + p.students.length, 0)

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
          value={MOCK_PARENTS.length}
          icon={Users}
          trend="up"
          trendValue="+14%"
          description="Registered on platform"
        />
        <StatCard
          title="Active Parents"
          value={activeParents}
          icon={Users}
          trend="up"
          trendValue="+10%"
          description="Recently active"
        />
        <StatCard
          title="Linked Students"
          value={totalStudents}
          icon={GraduationCap}
          trend="up"
          trendValue="+8%"
          description="Across all parents"
        />
        <StatCard
          title="Avg Children"
          value={(totalStudents / MOCK_PARENTS.length).toFixed(1)}
          icon={Users}
          trend="neutral"
          trendValue="1.6"
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
            data={MOCK_PARENTS}
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
