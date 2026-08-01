'use client'

import { BarChart3, Users, TrendingUp, FileText, GraduationCap, Calendar } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { StatCard } from '@/components/dashboard/stat-card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { AreaChart } from '@/components/charts/area-chart'
import { BarChart } from '@/components/charts/bar-chart'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

// ============================================================================
// ExamForge AI — Analytics Page
// ============================================================================
// Server Component. Displays overview stats, charts (area + bar),
// date range selector, and performance analytics.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Mock Chart Data
// ──────────────────────────────────────────────────────────────

const examTrendData = [
  { month: 'Aug', exams: 12, participants: 180 },
  { month: 'Sep', exams: 18, participants: 270 },
  { month: 'Oct', exams: 15, participants: 225 },
  { month: 'Nov', exams: 22, participants: 330 },
  { month: 'Dec', exams: 8, participants: 120 },
  { month: 'Jan', exams: 25, participants: 375 },
  { month: 'Feb', exams: 20, participants: 300 },
]

const subjectPerformanceData = [
  { subject: 'Mathematics', avgScore: 72, passRate: 78 },
  { subject: 'English', avgScore: 81, passRate: 88 },
  { subject: 'Physics', avgScore: 65, passRate: 62 },
  { subject: 'Chemistry', avgScore: 68, passRate: 70 },
  { subject: 'Biology', avgScore: 76, passRate: 82 },
  { subject: 'Economics', avgScore: 79, passRate: 85 },
]

const weeklyActivityData = [
  { week: 'Week 1', examsCreated: 5, examsCompleted: 8 },
  { week: 'Week 2', examsCreated: 3, examsCompleted: 12 },
  { week: 'Week 3', examsCreated: 7, examsCompleted: 6 },
  { week: 'Week 4', examsCreated: 4, examsCompleted: 10 },
]

// ──────────────────────────────────────────────────────────────
// Page Component
// ──────────────────────────────────────────────────────────────

export default function AnalyticsPage() {
  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Analytics</h1>
          <p className="text-sm text-muted-foreground">
            Track performance metrics, trends, and insights across your platform.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Select defaultValue="30d">
            <SelectTrigger className="h-9 w-[160px]">
              <Calendar className="h-4 w-4 mr-2 text-muted-foreground" />
              <SelectValue placeholder="Date range" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="7d">Last 7 days</SelectItem>
              <SelectItem value="30d">Last 30 days</SelectItem>
              <SelectItem value="90d">Last 90 days</SelectItem>
              <SelectItem value="1y">Last 12 months</SelectItem>
              <SelectItem value="all">All time</SelectItem>
            </SelectContent>
          </Select>
          <Button variant="outline" className="gap-2">
            <FileText className="h-4 w-4" />
            Export Report
          </Button>
        </div>
      </div>

      {/* Overview Stats */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Exams"
          value={120}
          icon={FileText}
          trend="up"
          trendValue="+18%"
          description="vs last period"
        />
        <StatCard
          title="Active Students"
          value={1840}
          icon={Users}
          trend="up"
          trendValue="+12%"
          description="vs last period"
        />
        <StatCard
          title="Avg Pass Rate"
          value="76.4%"
          icon={TrendingUp}
          trend="up"
          trendValue="+5%"
          description="vs last period"
        />
        <StatCard
          title="Avg Score"
          value="73.2%"
          icon={GraduationCap}
          trend="up"
          trendValue="+3%"
          description="vs last period"
        />
      </div>

      {/* Charts Section */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="performance">Performance</TabsTrigger>
          <TabsTrigger value="activity">Activity</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          <div className="grid gap-4 lg:grid-cols-2">
            {/* Exam Trend Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Exam Trends</CardTitle>
                <CardDescription>Number of exams and participants over time.</CardDescription>
              </CardHeader>
              <CardContent>
                <AreaChart
                  data={examTrendData}
                  xKey="month"
                  yKeys={['exams', 'participants']}
                  height={300}
                  showGrid={true}
                  showLegend={true}
                />
              </CardContent>
            </Card>

            {/* Subject Performance Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Subject Performance</CardTitle>
                <CardDescription>Average scores and pass rates by subject.</CardDescription>
              </CardHeader>
              <CardContent>
                <BarChart
                  data={subjectPerformanceData}
                  xKey="subject"
                  yKeys={['avgScore', 'passRate']}
                  height={300}
                  showGrid={true}
                  showLegend={true}
                />
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="performance" className="space-y-4">
          <div className="grid gap-4 lg:grid-cols-2">
            {/* Score Distribution */}
            <Card>
              <CardHeader>
                <CardTitle>Score Distribution</CardTitle>
                <CardDescription>Distribution of student scores across all exams.</CardDescription>
              </CardHeader>
              <CardContent>
                <BarChart
                  data={[
                    { range: '0-20%', count: 12 },
                    { range: '21-40%', count: 28 },
                    { range: '41-60%', count: 65 },
                    { range: '61-80%', count: 89 },
                    { range: '81-100%', count: 46 },
                  ]}
                  xKey="range"
                  yKeys={['count']}
                  height={300}
                  showGrid={true}
                  showLegend={false}
                />
              </CardContent>
            </Card>

            {/* Pass Rate by Subject */}
            <Card>
              <CardHeader>
                <CardTitle>Pass Rate by Subject</CardTitle>
                <CardDescription>Percentage of students passing each subject.</CardDescription>
              </CardHeader>
              <CardContent>
                <AreaChart
                  data={subjectPerformanceData}
                  xKey="subject"
                  yKeys={['passRate']}
                  height={300}
                  showGrid={true}
                  showLegend={false}
                />
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="activity" className="space-y-4">
          <div className="grid gap-4 lg:grid-cols-2">
            {/* Weekly Activity */}
            <Card>
              <CardHeader>
                <CardTitle>Weekly Activity</CardTitle>
                <CardDescription>Exams created vs completed each week.</CardDescription>
              </CardHeader>
              <CardContent>
                <BarChart
                  data={weeklyActivityData}
                  xKey="week"
                  yKeys={['examsCreated', 'examsCompleted']}
                  height={300}
                  showGrid={true}
                  showLegend={true}
                />
              </CardContent>
            </Card>

            {/* Participation Trend */}
            <Card>
              <CardHeader>
                <CardTitle>Participation Trend</CardTitle>
                <CardDescription>Student participation over time.</CardDescription>
              </CardHeader>
              <CardContent>
                <AreaChart
                  data={examTrendData}
                  xKey="month"
                  yKeys={['participants']}
                  height={300}
                  showGrid={true}
                  showLegend={false}
                />
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>

      {/* Quick Insights */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <BarChart3 className="h-5 w-5" />
            Quick Insights
          </CardTitle>
          <CardDescription>Key takeaways from the current data.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div className="rounded-lg border p-4">
              <p className="text-sm font-medium text-muted-foreground">Top Performing Subject</p>
              <p className="mt-1 text-lg font-bold">English</p>
              <p className="text-xs text-muted-foreground">88% pass rate • 81% avg score</p>
            </div>
            <div className="rounded-lg border p-4">
              <p className="text-sm font-medium text-muted-foreground">Needs Attention</p>
              <p className="mt-1 text-lg font-bold">Physics</p>
              <p className="text-xs text-muted-foreground">62% pass rate • 65% avg score</p>
            </div>
            <div className="rounded-lg border p-4">
              <p className="text-sm font-medium text-muted-foreground">Most Active Month</p>
              <p className="mt-1 text-lg font-bold">January</p>
              <p className="text-xs text-muted-foreground">25 exams • 375 participants</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
