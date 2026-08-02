import { requireAnyRole } from '@/lib/auth/require-auth'
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
  CreditCard,
} from 'lucide-react'
import Link from 'next/link'
import { getSuperAdminStats, getSuperAdminActivities } from '@/lib/services/dashboard-service'

export const dynamic = 'force-dynamic'

// ============================================================================
// ExamForge AI — Super Admin Dashboard
// ============================================================================
// Server Component. Requires super_admin role. Reads live platform stats.
// ============================================================================

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(amount)
}

function formatRelativeTime(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMs / 3600000)
  const diffDays = Math.floor(diffMs / 86400000)
  if (diffMins < 1) return 'Just now'
  if (diffMins < 60) return `${diffMins} min ago`
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays < 7) return `${diffDays}d ago`
  return date.toLocaleDateString()
}

export default async function SuperAdminDashboard() {
  const { user } = await requireAnyRole(['super_admin'])

  const firstName = user.fullName.split(' ')[0]

  const [stats, activities] = await Promise.all([
    getSuperAdminStats(),
    getSuperAdminActivities(),
  ])

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Welcome back, {firstName}</h1>
          <p className="text-muted-foreground mt-1">Platform administration overview and controls.</p>
        </div>
        <Badge variant="secondary" className="w-fit text-sm">
          <Shield className="h-3.5 w-3.5 mr-1" />
          Super Admin Dashboard
        </Badge>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Schools</CardTitle>
            <School className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.schools.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">{stats.activeSchools} active</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Users</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.users.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">Total platform users</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{formatCurrency(stats.revenue)}</div>
            <p className="text-xs text-muted-foreground">Total successful payments</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Exams</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.exams.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">Total exams created</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Payments</CardTitle>
            <CreditCard className="h-4 w-4 text-amber-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.pendingPayments}</div>
            <p className="text-xs text-muted-foreground">Awaiting processing</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Active Schools</CardTitle>
            <School className="h-4 w-4 text-emerald-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.activeSchools}</div>
            <p className="text-xs text-muted-foreground">Currently operational</p>
          </CardContent>
        </Card>
      </div>

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

      <div>
        <h2 className="text-lg font-semibold mb-4">Administration</h2>
        <div className="grid gap-4 grid-cols-2 sm:grid-cols-3 lg:grid-cols-6">
          <Link href={ROUTES.ADMIN_USERS}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardContent className="p-4 flex flex-col items-center gap-2 text-center"><div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center"><Users className="h-4 w-4 text-primary" /></div><span className="text-xs font-medium">Users</span></CardContent></Card></Link>
          <Link href={ROUTES.ADMIN_BILLING}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardContent className="p-4 flex flex-col items-center gap-2 text-center"><div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center"><DollarSign className="h-4 w-4 text-primary" /></div><span className="text-xs font-medium">Billing</span></CardContent></Card></Link>
          <Link href={ROUTES.ADMIN_AI_MANAGEMENT}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardContent className="p-4 flex flex-col items-center gap-2 text-center"><div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center"><Cpu className="h-4 w-4 text-primary" /></div><span className="text-xs font-medium">AI Mgmt</span></CardContent></Card></Link>
          <Link href={ROUTES.ADMIN_MARKETPLACE}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardContent className="p-4 flex flex-col items-center gap-2 text-center"><div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center"><Globe className="h-4 w-4 text-primary" /></div><span className="text-xs font-medium">Marketplace</span></CardContent></Card></Link>
          <Link href={ROUTES.ADMIN_SECURITY}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardContent className="p-4 flex flex-col items-center gap-2 text-center"><div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center"><Lock className="h-4 w-4 text-primary" /></div><span className="text-xs font-medium">Security</span></CardContent></Card></Link>
          <Link href={ROUTES.ADMIN_INFRASTRUCTURE}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardContent className="p-4 flex flex-col items-center gap-2 text-center"><div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center"><Database className="h-4 w-4 text-primary" /></div><span className="text-xs font-medium">Infra</span></CardContent></Card></Link>
        </div>
      </div>

      <Separator />

      <div>
        <h2 className="text-lg font-semibold mb-4">Recent Activity</h2>
        <Card>
          {activities.length === 0 ? (
            <CardContent className="p-8 text-center"><p className="text-muted-foreground">No recent activity to display.</p></CardContent>
          ) : (
            <div className="divide-y">
              {activities.map((activity) => (
                <div key={activity.id} className="flex items-center gap-3 p-4">
                  <div className="h-8 w-8 rounded-full bg-muted flex items-center justify-center shrink-0">
                    {activity.type === 'school' && <School className="h-4 w-4 text-muted-foreground" />}
                    {activity.type === 'user' && <Users className="h-4 w-4 text-muted-foreground" />}
                    {activity.type === 'revenue' && <DollarSign className="h-4 w-4 text-muted-foreground" />}
                    {activity.type === 'system' && <Activity className="h-4 w-4 text-muted-foreground" />}
                  </div>
                  <div className="flex-1 min-w-0"><p className="text-sm truncate">{activity.description}</p></div>
                  <div className="flex items-center gap-1 text-xs text-muted-foreground shrink-0"><Clock className="h-3 w-3" />{formatRelativeTime(activity.timestamp)}</div>
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>
    </div>
  )
}
