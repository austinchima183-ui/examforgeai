import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { ROUTES } from '@/lib/constants/routes'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import {
  Shield,
  School,
  Users,
  DollarSign,
  FileText,
  Activity,
  Database,
  Cpu,
  BarChart3,
  Globe,
  Lock,
  Clock,
} from 'lucide-react'
import Link from 'next/link'

// ============================================================================
// ExamForge AI — Super Admin Dashboard
// ============================================================================
// Server Component. Platform stats, quick actions, and recent activity.
// ============================================================================

interface ActivityItem {
  id: string
  description: string
  timestamp: string
  type: 'school' | 'user' | 'revenue' | 'system'
}

// Placeholder data — in production, these would be fetched from Supabase
const PLACEHOLDER_STATS = {
  schools: 156,
  users: 12450,
  revenue: '$284,500',
  exams: 34200,
}

const PLACEHOLDER_ACTIVITIES: ActivityItem[] = [
  {
    id: '1',
    description: 'New school registered: Lagos International Academy',
    timestamp: '30 minutes ago',
    type: 'school',
  },
  {
    id: '2',
    description: 'Platform reached 12,000 active users milestone',
    timestamp: '2 hours ago',
    type: 'user',
  },
  {
    id: '3',
    description: 'Monthly revenue report generated — $284,500',
    timestamp: '1 day ago',
    type: 'revenue',
  },
  {
    id: '4',
    description: 'System health check completed — all services operational',
    timestamp: '1 day ago',
    type: 'system',
  },
]

export default async function SuperAdminDashboard() {
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
            Platform administration overview and controls.
          </p>
        </div>
        <Badge variant="secondary" className="w-fit text-sm">
          <Shield className="h-3.5 w-3.5 mr-1" />
          Super Admin Dashboard
        </Badge>
      </div>

      {/* Platform Stats */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Schools</CardTitle>
            <School className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.schools.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">Registered schools</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Users</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.users.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">Total platform users</p>
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

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Exams</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.exams.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">Total exams created</p>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="text-lg font-semibold mb-4">Quick Actions</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <Link href={ROUTES.ADMIN_SCHOOLS}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center">
                    <School className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-base">Manage Schools</CardTitle>
                    <CardDescription>View and manage all registered schools</CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          </Link>

          <Link href={ROUTES.ADMIN_ANALYTICS}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center">
                    <BarChart3 className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-base">View Analytics</CardTitle>
                    <CardDescription>Platform-wide analytics and insights</CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          </Link>

          <Link href={ROUTES.ADMIN_INFRASTRUCTURE}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center">
                    <Activity className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-base">System Health</CardTitle>
                    <CardDescription>Monitor infrastructure and service status</CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          </Link>
        </div>
      </div>

      {/* Admin Quick Links */}
      <div>
        <h2 className="text-lg font-semibold mb-4">Administration</h2>
        <div className="grid gap-4 grid-cols-2 sm:grid-cols-3 lg:grid-cols-6">
          <Link href={ROUTES.ADMIN_USERS}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardContent className="p-4 flex flex-col items-center gap-2 text-center">
                <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <Users className="h-4 w-4 text-primary" />
                </div>
                <span className="text-xs font-medium">Users</span>
              </CardContent>
            </Card>
          </Link>

          <Link href={ROUTES.ADMIN_BILLING}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardContent className="p-4 flex flex-col items-center gap-2 text-center">
                <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <DollarSign className="h-4 w-4 text-primary" />
                </div>
                <span className="text-xs font-medium">Billing</span>
              </CardContent>
            </Card>
          </Link>

          <Link href={ROUTES.ADMIN_AI_MANAGEMENT}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardContent className="p-4 flex flex-col items-center gap-2 text-center">
                <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <Cpu className="h-4 w-4 text-primary" />
                </div>
                <span className="text-xs font-medium">AI Mgmt</span>
              </CardContent>
            </Card>
          </Link>

          <Link href={ROUTES.ADMIN_MARKETPLACE}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardContent className="p-4 flex flex-col items-center gap-2 text-center">
                <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <Globe className="h-4 w-4 text-primary" />
                </div>
                <span className="text-xs font-medium">Marketplace</span>
              </CardContent>
            </Card>
          </Link>

          <Link href={ROUTES.ADMIN_SECURITY}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardContent className="p-4 flex flex-col items-center gap-2 text-center">
                <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <Lock className="h-4 w-4 text-primary" />
                </div>
                <span className="text-xs font-medium">Security</span>
              </CardContent>
            </Card>
          </Link>

          <Link href={ROUTES.ADMIN_INFRASTRUCTURE}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardContent className="p-4 flex flex-col items-center gap-2 text-center">
                <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <Database className="h-4 w-4 text-primary" />
                </div>
                <span className="text-xs font-medium">Infra</span>
              </CardContent>
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
                  {activity.type === 'school' && <School className="h-4 w-4 text-muted-foreground" />}
                  {activity.type === 'user' && <Users className="h-4 w-4 text-muted-foreground" />}
                  {activity.type === 'revenue' && <DollarSign className="h-4 w-4 text-muted-foreground" />}
                  {activity.type === 'system' && <Activity className="h-4 w-4 text-muted-foreground" />}
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
