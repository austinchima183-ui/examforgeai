import { requireAnyRole } from '@/lib/auth/require-auth'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import {
  GraduationCap, FileText, BarChart3, Target, Clock, Sparkles,
  BookOpen, Brain, CheckCircle2, ClipboardList,
} from 'lucide-react'
import Link from 'next/link'
import { ROUTES } from '@/lib/constants/routes'
import { getStudentStats, getStudentActivities } from '@/lib/services/dashboard-service'

export const dynamic = 'force-dynamic'

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

export default async function StudentDashboard() {
  const { user } = await requireAnyRole(['student', 'parent'])

  const firstName = user.fullName.split(' ')[0]

  const [stats, activities] = await Promise.all([
    getStudentStats(user.id),
    getStudentActivities(user.id),
  ])

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Welcome back, {firstName}</h1>
          <p className="text-muted-foreground mt-1">Ready to continue your learning journey?</p>
        </div>
        <Badge variant="secondary" className="w-fit text-sm">
          <GraduationCap className="h-3.5 w-3.5 mr-1" />
          Student Dashboard
        </Badge>
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2"><CardTitle className="text-sm font-medium">Upcoming Exams</CardTitle><Clock className="h-4 w-4 text-muted-foreground" /></CardHeader>
          <CardContent><div className="text-2xl font-bold">{stats.upcomingExams}</div><p className="text-xs text-muted-foreground">Scheduled exams</p></CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2"><CardTitle className="text-sm font-medium">Completed</CardTitle><CheckCircle2 className="h-4 w-4 text-muted-foreground" /></CardHeader>
          <CardContent><div className="text-2xl font-bold">{stats.completed}</div><p className="text-xs text-muted-foreground">Exams taken</p></CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2"><CardTitle className="text-sm font-medium">Average Score</CardTitle><BarChart3 className="h-4 w-4 text-muted-foreground" /></CardHeader>
          <CardContent><div className="text-2xl font-bold">{stats.averageScore}%</div><p className="text-xs text-muted-foreground">Across all exams</p></CardContent>
        </Card>
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-4">Quick Actions</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <Link href={ROUTES.STUDENT_PRACTICE}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardHeader><div className="flex items-center gap-3"><div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center"><Target className="h-5 w-5 text-primary" /></div><div><CardTitle className="text-base">Take Exam</CardTitle><CardDescription>View and take your scheduled exams</CardDescription></div></div></CardHeader></Card></Link>
          <Link href={ROUTES.STUDENT_PROGRESS}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardHeader><div className="flex items-center gap-3"><div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center"><BarChart3 className="h-5 w-5 text-primary" /></div><div><CardTitle className="text-base">View Results</CardTitle><CardDescription>Check your scores and performance</CardDescription></div></div></CardHeader></Card></Link>
          <Link href={ROUTES.STUDENT_PRACTICE}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardHeader><div className="flex items-center gap-3"><div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center"><Sparkles className="h-5 w-5 text-primary" /></div><div><CardTitle className="text-base">Practice</CardTitle><CardDescription>AI-powered practice sessions</CardDescription></div></div></CardHeader></Card></Link>
        </div>
      </div>

      <Separator />

      <div>
        <h2 className="text-lg font-semibold mb-4">Learning Tools</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <Link href={ROUTES.STUDENT_FLASHCARDS}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardContent className="p-4 flex items-center gap-3"><div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center"><BookOpen className="h-4 w-4 text-primary" /></div><span className="text-sm font-medium">Flashcards</span></CardContent></Card></Link>
          <Link href={ROUTES.STUDENT_AI_TUTOR}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardContent className="p-4 flex items-center gap-3"><div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center"><Brain className="h-4 w-4 text-primary" /></div><span className="text-sm font-medium">AI Tutor</span></CardContent></Card></Link>
          <Link href={ROUTES.STUDENT_STUDY_PLANNER}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardContent className="p-4 flex items-center gap-3"><div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center"><ClipboardList className="h-4 w-4 text-primary" /></div><span className="text-sm font-medium">Study Planner</span></CardContent></Card></Link>
          <Link href={ROUTES.STUDENT_RESOURCES}><Card className="hover:shadow-md transition-shadow cursor-pointer h-full"><CardContent className="p-4 flex items-center gap-3"><div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center"><Sparkles className="h-4 w-4 text-primary" /></div><span className="text-sm font-medium">Resources</span></CardContent></Card></Link>
        </div>
      </div>

      <Separator />

      <div>
        <h2 className="text-lg font-semibold mb-4">Recent Activity</h2>
        <Card>
          {activities.length === 0 ? (
            <CardContent className="p-8 text-center"><p className="text-muted-foreground">No recent activity. Take an exam to get started!</p></CardContent>
          ) : (
            <div className="divide-y">
              {activities.map((activity) => (
                <div key={activity.id} className="flex items-center gap-3 p-4">
                  <div className="h-8 w-8 rounded-full bg-muted flex items-center justify-center shrink-0">
                    {activity.type === 'exam' && <FileText className="h-4 w-4 text-muted-foreground" />}
                    {activity.type === 'practice' && <Target className="h-4 w-4 text-muted-foreground" />}
                    {activity.type === 'result' && <CheckCircle2 className="h-4 w-4 text-muted-foreground" />}
                    {activity.type === 'achievement' && <Sparkles className="h-4 w-4 text-muted-foreground" />}
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
