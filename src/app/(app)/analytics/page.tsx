'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { StatCard } from '@/components/dashboard/stat-card'
import { AreaChart } from '@/components/charts/area-chart'
import { BarChart } from '@/components/charts/bar-chart'
import { BarChart3, Users, TrendingUp, Award, Download, Loader2, AlertCircle, Sparkles, AlertTriangle } from 'lucide-react'
import type { AnalyticsOverview } from '@/lib/services/analytics-service'

// ============================================================================
// ExamForge AI — Analytics Page
// ============================================================================
// Client component with live Supabase data. No mock data.
// Features: Student Growth, Revenue, Exam Activity, Active Users,
// Usage metrics, School Rankings. Loading, empty, and error states.
// ============================================================================

type DateRange = '7d' | '30d' | '90d' | '1y' | 'all'

export default function AnalyticsPage() {
  const [data, setData] = useState<AnalyticsOverview | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [dateRange, setDateRange] = useState<DateRange>('30d')

  useEffect(() => {
    async function fetchAnalytics() {
      setLoading(true)
      setError(null)

      try {
        const supabase = createClient()
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) return

        const { data: profile } = await supabase
          .from('profiles')
          .select('school_id, role')
          .eq('id', user.id)
          .single()

        const profileData = profile as { school_id: string | null; role: string } | null
        const role = (profileData?.role ?? 'student') as 'student' | 'teacher' | 'school_admin' | 'super_admin'
        const schoolId = profileData?.school_id

        // Call the API route
        const res = await fetch(`/api/analytics?range=${dateRange}`)
        if (!res.ok) {
          throw new Error('Failed to fetch analytics data')
        }
        const result = await res.json()
        setData(result)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An unexpected error occurred')
      } finally {
        setLoading(false)
      }
    }

    fetchAnalytics()
  }, [dateRange])

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-center p-12">
          <div className="flex flex-col items-center gap-3">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
            <p className="text-sm text-muted-foreground">Loading analytics...</p>
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="space-y-6">
        <Card className="border-destructive/50">
          <CardContent className="p-8 text-center">
            <div className="flex justify-center mb-4">
              <div className="h-16 w-16 rounded-full bg-destructive/10 flex items-center justify-center">
                <AlertCircle className="h-8 w-8 text-destructive" />
              </div>
            </div>
            <h3 className="text-lg font-medium">Failed to load analytics</h3>
            <p className="text-sm text-muted-foreground mt-1">{error}</p>
            <Button
              variant="outline"
              className="mt-4"
              onClick={() => window.location.reload()}
            >
              Try Again
            </Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  if (!data) {
    return (
      <div className="space-y-6">
        <Card>
          <CardContent className="p-8 text-center">
            <div className="flex justify-center mb-4">
              <div className="h-16 w-16 rounded-full bg-muted flex items-center justify-center">
                <BarChart3 className="h-8 w-8 text-muted-foreground" />
              </div>
            </div>
            <h3 className="text-lg font-medium">No analytics data available</h3>
            <p className="text-sm text-muted-foreground mt-1">
              Analytics will appear once there is exam activity on the platform.
            </p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Analytics</h1>
          <p className="text-sm text-muted-foreground">
            Detailed insights into exam performance, student progress, and platform activity.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={dateRange} onValueChange={(v) => setDateRange(v as DateRange)}>
            <SelectTrigger className="h-9 w-[140px]">
              <SelectValue placeholder="Select range" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="7d">Last 7 days</SelectItem>
              <SelectItem value="30d">Last 30 days</SelectItem>
              <SelectItem value="90d">Last 90 days</SelectItem>
              <SelectItem value="1y">Last year</SelectItem>
              <SelectItem value="all">All time</SelectItem>
            </SelectContent>
          </Select>
          <Button variant="outline" size="sm" className="gap-2">
            <Download className="h-4 w-4" />
            Export Report
          </Button>
        </div>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Exams"
          value={data.stats.totalExams}
          icon={BarChart3}
          description="Exams on platform"
        />
        <StatCard
          title="Active Students"
          value={data.stats.activeStudents}
          icon={Users}
          description="Currently enrolled"
        />
        <StatCard
          title="Avg Pass Rate"
          value={`${data.stats.avgPassRate}%`}
          icon={TrendingUp}
          description="Across all exams"
        />
        <StatCard
          title="Avg Score"
          value={`${data.stats.avgScore}%`}
          icon={Award}
          description="Average percentage"
        />
      </div>

      {/* Charts */}
      <Tabs defaultValue="overview" className="space-y-6">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="performance">Performance</TabsTrigger>
          <TabsTrigger value="activity">Activity</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-6">
          <div className="grid gap-6 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Exam Activity Trend</CardTitle>
                <CardDescription>Monthly submissions and average scores</CardDescription>
              </CardHeader>
              <CardContent>
                {data.examTrend.length > 0 ? (
                  <AreaChart
                    data={data.examTrend}
                    xKey="label"
                    yKeys={['value', 'value2']}
                    colors={['hsl(var(--chart-1))', 'hsl(var(--chart-2))']}
                    height={300}
                  />
                ) : (
                  <div className="flex items-center justify-center h-[300px] text-muted-foreground text-sm">
                    No exam activity data available yet
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Subject Performance</CardTitle>
                <CardDescription>Average scores by subject</CardDescription>
              </CardHeader>
              <CardContent>
                {data.subjectPerformance.length > 0 ? (
                  <BarChart
                    data={data.subjectPerformance}
                    xKey="subject"
                    yKeys={['score']}
                    colors={['hsl(var(--chart-1))']}
                    height={300}
                  />
                ) : (
                  <div className="flex items-center justify-center h-[300px] text-muted-foreground text-sm">
                    No subject performance data available yet
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Performance Tab */}
        <TabsContent value="performance" className="space-y-6">
          <div className="grid gap-6 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Score Distribution</CardTitle>
                <CardDescription>Average scores by subject</CardDescription>
              </CardHeader>
              <CardContent>
                {data.subjectPerformance.length > 0 ? (
                  <BarChart
                    data={data.subjectPerformance}
                    xKey="subject"
                    yKeys={['score', 'passRate']}
                    colors={['hsl(var(--chart-1))', 'hsl(var(--chart-3))']}
                    height={300}
                  />
                ) : (
                  <div className="flex items-center justify-center h-[300px] text-muted-foreground text-sm">
                    No performance data available yet
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Pass Rate by Subject</CardTitle>
                <CardDescription>Percentage of students passing each subject</CardDescription>
              </CardHeader>
              <CardContent>
                {data.subjectPerformance.length > 0 ? (
                  <AreaChart
                    data={data.subjectPerformance}
                    xKey="subject"
                    yKeys={['passRate']}
                    colors={['hsl(var(--chart-3))']}
                    height={300}
                  />
                ) : (
                  <div className="flex items-center justify-center h-[300px] text-muted-foreground text-sm">
                    No pass rate data available yet
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Activity Tab */}
        <TabsContent value="activity" className="space-y-6">
          <div className="grid gap-6 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Weekly Activity</CardTitle>
                <CardDescription>Exam submissions by week</CardDescription>
              </CardHeader>
              <CardContent>
                {data.weeklyActivity.length > 0 ? (
                  <BarChart
                    data={data.weeklyActivity}
                    xKey="week"
                    yKeys={['exams', 'participants']}
                    colors={['hsl(var(--chart-1))', 'hsl(var(--chart-2))']}
                    height={300}
                  />
                ) : (
                  <div className="flex items-center justify-center h-[300px] text-muted-foreground text-sm">
                    No weekly activity data available yet
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Participation Trend</CardTitle>
                <CardDescription>Student engagement over time</CardDescription>
              </CardHeader>
              <CardContent>
                {data.weeklyActivity.length > 0 ? (
                  <AreaChart
                    data={data.weeklyActivity}
                    xKey="week"
                    yKeys={['exams', 'participants']}
                    colors={['hsl(var(--chart-1))', 'hsl(var(--chart-2))']}
                    height={300}
                  />
                ) : (
                  <div className="flex items-center justify-center h-[300px] text-muted-foreground text-sm">
                    No participation trend data available yet
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>

      {/* Quick Insights */}
      <Card>
        <CardHeader>
          <CardTitle>Quick Insights</CardTitle>
          <CardDescription>Key takeaways from your analytics data</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 sm:grid-cols-3">
            <div className="flex items-center gap-3 p-3 rounded-lg bg-emerald-50 dark:bg-emerald-950/20">
              <div className="h-9 w-9 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center">
                <Sparkles className="h-4 w-4 text-emerald-600" />
              </div>
              <div>
                <p className="text-sm font-medium">Top Performing Subject</p>
                <p className="text-xs text-muted-foreground">{data.quickInsights.topSubject ?? 'No data yet'}</p>
              </div>
            </div>

            <div className="flex items-center gap-3 p-3 rounded-lg bg-amber-50 dark:bg-amber-950/20">
              <div className="h-9 w-9 rounded-lg bg-amber-100 dark:bg-amber-900/30 flex items-center justify-center">
                <AlertTriangle className="h-4 w-4 text-amber-600" />
              </div>
              <div>
                <p className="text-sm font-medium">Needs Attention</p>
                <p className="text-xs text-muted-foreground">{data.quickInsights.needsAttention ?? 'No data yet'}</p>
              </div>
            </div>

            <div className="flex items-center gap-3 p-3 rounded-lg bg-blue-50 dark:bg-blue-950/20">
              <div className="h-9 w-9 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                <TrendingUp className="h-4 w-4 text-blue-600" />
              </div>
              <div>
                <p className="text-sm font-medium">Most Active Month</p>
                <p className="text-xs text-muted-foreground">{data.quickInsights.mostActiveMonth ?? 'No data yet'}</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* School Rankings */}
      {data.schoolRankings.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>School Rankings</CardTitle>
            <CardDescription>Top performing schools by student count and exam activity</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {data.schoolRankings.map((school, idx) => (
                <div key={school.id} className="flex items-center gap-3 p-3 rounded-lg border">
                  <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center text-sm font-bold text-primary">
                    {idx + 1}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{school.name}</p>
                    <p className="text-xs text-muted-foreground">{school.totalStudents} students · {school.totalExams} exams</p>
                  </div>
                  <Badge variant="outline" className="shrink-0">
                    {school.totalStudents} students
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
