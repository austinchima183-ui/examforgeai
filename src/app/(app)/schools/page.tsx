'use client'

import { type ColumnDef } from '@tanstack/react-table'
import { School, Plus, MapPin, Users, Phone, Mail } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

// ============================================================================
// ExamForge AI — Schools Management Page
// ============================================================================
// Server Component. Displays a list of schools with search/filter,
// stats overview, and an add school button for admin roles.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

interface School {
  id: string
  name: string
  location: string
  type: 'primary' | 'secondary' | 'tertiary' | 'mixed'
  status: 'active' | 'inactive' | 'suspended'
  studentCount: number
  teacherCount: number
  adminEmail: string
  adminPhone: string
  createdAt: string
}

// ──────────────────────────────────────────────────────────────
// Mock Data
// ──────────────────────────────────────────────────────────────

const MOCK_SCHOOLS: School[] = [
  {
    id: '1',
    name: 'Springfield Academy',
    location: 'Lagos, Nigeria',
    type: 'secondary',
    status: 'active',
    studentCount: 1240,
    teacherCount: 85,
    adminEmail: 'admin@springfield.edu',
    adminPhone: '+234-801-234-5678',
    createdAt: '2023-01-15T10:00:00Z',
  },
  {
    id: '2',
    name: 'Greenfield International School',
    location: 'Abuja, Nigeria',
    type: 'mixed',
    status: 'active',
    studentCount: 890,
    teacherCount: 62,
    adminEmail: 'admin@greenfield.edu',
    adminPhone: '+234-802-345-6789',
    createdAt: '2023-03-22T14:30:00Z',
  },
  {
    id: '3',
    name: 'Riverside Primary School',
    location: 'Port Harcourt, Nigeria',
    type: 'primary',
    status: 'active',
    studentCount: 450,
    teacherCount: 32,
    adminEmail: 'admin@riverside.edu',
    adminPhone: '+234-803-456-7890',
    createdAt: '2023-06-10T08:15:00Z',
  },
  {
    id: '4',
    name: 'Hilltop College',
    location: 'Ibadan, Nigeria',
    type: 'tertiary',
    status: 'inactive',
    studentCount: 0,
    teacherCount: 0,
    adminEmail: 'admin@hilltop.edu',
    adminPhone: '+234-804-567-8901',
    createdAt: '2022-11-05T16:45:00Z',
  },
  {
    id: '5',
    name: 'Sunrise Academy',
    location: 'Kano, Nigeria',
    type: 'secondary',
    status: 'suspended',
    studentCount: 320,
    teacherCount: 24,
    adminEmail: 'admin@sunrise.edu',
    adminPhone: '+234-805-678-9012',
    createdAt: '2023-09-01T12:00:00Z',
  },
]

// ──────────────────────────────────────────────────────────────
// Column Definitions
// ──────────────────────────────────────────────────────────────

const statusVariantMap: Record<School['status'], 'default' | 'secondary' | 'destructive'> = {
  active: 'default',
  inactive: 'secondary',
  suspended: 'destructive',
}

const typeLabelMap: Record<School['type'], string> = {
  primary: 'Primary',
  secondary: 'Secondary',
  tertiary: 'Tertiary',
  mixed: 'Mixed',
}

const columns: ColumnDef<School, unknown>[] = [
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
          <p className="text-xs text-muted-foreground">{row.original.adminEmail}</p>
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
        {row.getValue('location')}
      </div>
    ),
  },
  {
    accessorKey: 'type',
    header: 'Type',
    cell: ({ row }) => (
      <Badge variant="outline">{typeLabelMap[row.getValue('type') as School['type']]}</Badge>
    ),
  },
  {
    accessorKey: 'studentCount',
    header: 'Students',
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <Users className="h-3.5 w-3.5 text-muted-foreground" />
        {Number(row.getValue('studentCount')).toLocaleString()}
      </div>
    ),
  },
  {
    accessorKey: 'teacherCount',
    header: 'Teachers',
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <Users className="h-3.5 w-3.5 text-muted-foreground" />
        {Number(row.getValue('teacherCount')).toLocaleString()}
      </div>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => {
      const status = row.getValue('status') as School['status']
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

export default function SchoolsPage() {
  const activeSchools = MOCK_SCHOOLS.filter((s) => s.status === 'active').length
  const totalStudents = MOCK_SCHOOLS.reduce((sum, s) => sum + s.studentCount, 0)
  const totalTeachers = MOCK_SCHOOLS.reduce((sum, s) => sum + s.teacherCount, 0)

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Schools</h1>
          <p className="text-sm text-muted-foreground">
            Manage and monitor all registered schools on the platform.
          </p>
        </div>
        <Button className="gap-2">
          <Plus className="h-4 w-4" />
          Add School
        </Button>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Schools"
          value={MOCK_SCHOOLS.length}
          icon={School}
          trend="up"
          trendValue="+12%"
          description="Registered on platform"
        />
        <StatCard
          title="Active Schools"
          value={activeSchools}
          icon={School}
          trend="up"
          trendValue="+8%"
          description="Currently active"
        />
        <StatCard
          title="Total Students"
          value={totalStudents.toLocaleString()}
          icon={Users}
          trend="up"
          trendValue="+15%"
          description="Across all schools"
        />
        <StatCard
          title="Total Teachers"
          value={totalTeachers.toLocaleString()}
          icon={Users}
          trend="neutral"
          trendValue="+3%"
          description="Across all schools"
        />
      </div>

      {/* Data Table */}
      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <CardTitle>All Schools</CardTitle>
              <CardDescription>A list of all registered schools and their details.</CardDescription>
            </div>
            <div className="flex items-center gap-2">
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[140px]">
                  <SelectValue placeholder="Filter by type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Types</SelectItem>
                  <SelectItem value="primary">Primary</SelectItem>
                  <SelectItem value="secondary">Secondary</SelectItem>
                  <SelectItem value="tertiary">Tertiary</SelectItem>
                  <SelectItem value="mixed">Mixed</SelectItem>
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
                  <SelectItem value="suspended">Suspended</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={MOCK_SCHOOLS}
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
