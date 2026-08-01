import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { ROUTES } from '@/lib/constants/routes'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import {
  BookOpen,
  Users,
  FileText,
  Sparkles,
  BarChart3,
  Plus,
  ClipboardList,
  Clock,
  CheckCircle2,
  GraduationCap,
} from 'lucide-react'
import Link from 'next/link'

// ============================================================================
// ExamForge AI — Teacher Dashboard
// ============================================================================
// Server Component. Welcome section with teacher name, stats cards,
// quick actions, and recent activity list.
// ============================================================================

interface ActivityItem {
  id: string
  description: string
  timestamp: string
  type: 'exam' | 'question' | 'result' | 'class'
}

// Placeholder data — in production, these would be fetched from Supabase
const PLACEHOLDER_STATS = {
  classes: 5,
  students: 128,
  exams: 12,
  questions: 340,
}

const PLACEHOLDER_ACTIVITIES: ActivityItem[] = [
  {
    id: '1',
    description: 'Published "Mathematics Mid-Term" exam for SS2A',
    timestamp: '2 hours ago',
    type: 'exam',
  },
  {
    id: '2',
    description: 'Generated 15 AI questions for Physics Chapter 4',
    timestamp: '5 hours ago',
    type: 'question',
  },
  {
    id: '3',
    description: 'Graded 32 submissions for English Essay',
    timestamp: '1 day ago',
    type: 'result',
  },
  {
    id: '4',
    description: 'Added 3 new students to SS1B class',
    timestamp: '2 days ago',
    type: 'class',
  },
]

export default async function TeacherDashboard() {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect(ROUTES.LOGIN)
  }

  const fullName = user.user_metadata?.full_name ?? user.email?.split('@')[0] ?? 'Teacher'
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
            Here&apos;s an overview of your teaching workspace.
          </p>
        </div>
        <Badge variant="secondary" className="w-fit text-sm">
          <BookOpen className="h-3.5 w-3.5 mr-1" />
          Teacher Dashboard
        </Badge>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Classes</CardTitle>
            <BookOpen className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.classes}</div>
            <p className="text-xs text-muted-foreground">Active classes</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Students</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.students}</div>
            <p className="text-xs text-muted-foreground">Total students</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Exams</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.exams}</div>
            <p className="text-xs text-muted-foreground">Exams created</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Questions</CardTitle>
            <Sparkles className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{PLACEHOLDER_STATS.questions}</div>
            <p className="text-xs text-muted-foreground">In your question bank</p>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="text-lg font-semibold mb-4">Quick Actions</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <Link href={ROUTES.EXAM_CREATE}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center">
                    <Plus className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-base">Create Exam</CardTitle>
                    <CardDescription>Build a new exam from scratch or a template</CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          </Link>

          <Link href={ROUTES.EXAMS}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center">
                    <BarChart3 className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-base">View Results</CardTitle>
                    <CardDescription>Review exam submissions and analytics</CardDescription>
                  </div>
                </div>
              </CardHeader>
            </Card>
          </Link>

          <Link href={ROUTES.QUESTIONS_CREATE}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer h-full">
              <CardHeader>
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center">
                    <Sparkles className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-base">Generate Questions</CardTitle>
                    <CardDescription>Use AI to create questions instantly</CardDescription>
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
                  {activity.type === 'exam' && <FileText className="h-4 w-4 text-muted-foreground" />}
                  {activity.type === 'question' && <Sparkles className="h-4 w-4 text-muted-foreground" />}
                  {activity.type === 'result' && <ClipboardList className="h-4 w-4 text-muted-foreground" />}
                  {activity.type === 'class' && <GraduationCap className="h-4 w-4 text-muted-foreground" />}
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
