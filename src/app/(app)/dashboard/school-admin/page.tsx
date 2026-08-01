import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { ROUTES } from '@/lib/constants/routes'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import {
  School,
  Users,
  FileText,
  CreditCard,
  BarChart3,
  UserPlus,
  Settings,
  Clock,
  BookOpen,
  GraduationCap,
  DollarSign,
} from 'lucide-react'
import Link from 'next/link'

// ============================================================================
// ExamForge AI — School Admin Dashboard
// ============================================================================
// Server Component. Welcome section with admin name, stats cards,
// quick actions, and recent activity list.
// ============================================================================

interface ActivityItem {
  id: string
  description: string
  timestamp: string
  type: 'teacher' | 'student' | 'exam' | 'billing'
}

// Placeholder data — in production, these would be fetched from Supabase
const PLACEHOLDER_STATS = {
  teachers: 24,
  students: 480,
  exams: 85,
  revenue: '$12,450',
}

const PLACEHOLDER_ACTIVITIES: ActivityItem[] = [
  {
    id: '1',
    description: 'New teacher account created: Dr. Sarah Johnson',
    timestamp: '1 hour ago',
    type: 'teacher',
  },
  {
    id: '2',
    description: '15 new students enrolled in SS1 class',
    timestamp: '5 hours ago',
    type: 'student',
  },
  {
    id: '3',
    description: 'Monthly billing invoice generated — $1,250',
    timestamp: '1 day ago',
    type: 'billing',
  },
  {
    id: '4',
    description: 'Mid-term exams published for all SS2 classes',
    timestamp: '2 days ago',
    type: 'exam',
  },
]

export default async function SchoolAdminDashboard() {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect(ROUTES.LOGIN)
  }

  const fullName = user.user_metadata?.full_name ?? user.email?.split('@')[0] ?? 'Admin'
  const firstName = fullName.split(' ')[0]

  return (
    <div className="space-y-6">
      {/* Welcome Section */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">
            Welcome back, {firstName} 👋
          </h1>
          <p className="text-muted-foreground mt-1">
            Here&apos;s an overview of your school administration.
          </p>
        </div>
        <Badge variant="secondary" className="w-fit text-sm">
          <School className="h-3.5 w-3.5 mr-1" />
          School Admin Dashboard
        </Badge>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Teachers</CardTitle>
            <BookOpen className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.teachers}</div>
            <p className="text-xs text-muted-foreground">Active teachers</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Students</CardTitle>
            <GraduationCap className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.students}</div>
            <p className="text-xs text-muted-foreground">Enrolled students</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Exams</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.exams}</div>
            <p className="text-xs text-muted-foreground">Total exams created</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.revenue}</div>
            <p className="text-xs text-muted-foreground">This quarter</p>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="text-lg font-semibold mb-4">Quick Actions</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <Link href={ROUTES.SCHOOL_SETTINGS}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center">
                    <Settings className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-base">Manage School</CardTitle>
                    <CardDescription>Configure school settings and preferences</CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          </Link>

          <Link href={ROUTES.ANALYTICS}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center">
                    <BarChart3 className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-base">View Reports</CardTitle>
                    <CardDescription>Analyze school performance and trends</CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          </Link>

          <Link href={ROUTES.SCHOOL_USERS}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center">
                    <UserPlus className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-base">Add Teacher</CardTitle>
                    <CardDescription>Invite or create teacher accounts</CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          </Link>
        </div>
      </div>

      <Separator />

      {/* Recent Activity */}
      <div>
        <h2 className="text-lg font-semibold mb-4">Recent Activity</h2>
        <Card>
          <div className="divide-y">
            {PLACEHOLDER_ACTIVITIES.map((activity) => (
              <div key={activity.id} className="flex items-center gap-3 p-4">
                <div className="h-8 w-8 rounded-full bg-muted flex items-center justify-center shrink-0">
                  {activity.type === 'teacher' && <BookOpen className="h-4 w-4 text-muted-foreground" />}
                  {activity.type === 'student' && <GraduationCap className="h-4 w-4 text-muted-foreground" />}
                  {activity.type === 'exam' && <FileText className="h-4 w-4 text-muted-foreground" />}
                  {activity.type === 'billing' && <CreditCard className="h-4 w-4 text-muted-foreground" />}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm truncate">{activity.description}</p>
                </div>
                <div className="flex items-center gap-1 text-xs text-muted-foreground shrink-0">
                  <Clock className="h-3 w-3" />
                  {activity.timestamp}
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
