import { requireAuth } from '@/lib/auth/require-auth'
import { type ColumnDef } from '@tanstack/react-table'
import { HelpCircle, Sparkles, BookOpen, FileText } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ViewButton } from '@/components/buttons/view-button'
import { QuestionBankActions } from '@/components/buttons/question-bank-actions'
import { CreateQuestionDialog } from '@/components/dialogs/create-question-dialog'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { getQuestionBankData } from '@/lib/services/question-bank-service'
import type { QuestionListItem } from '@/lib/services/question-bank-service'

export const dynamic = 'force-dynamic'

// ============================================================================
// ExamForge AI — Question Bank Page
// ============================================================================
// Server Component. Displays questions from Supabase with real data.
// No mock data. All stats and tables are live.
// ============================================================================

const typeLabelMap: Record<string, string> = {
  multiple_choice: 'Multiple Choice',
  multi_select: 'Multi Select',
  true_false: 'True/False',
  short_answer: 'Short Answer',
  essay: 'Essay',
  fill_in_blank: 'Fill in Blank',
  matching: 'Matching',
  ordering: 'Ordering',
  numerical: 'Numerical',
}

const difficultyVariantMap: Record<string, 'default' | 'secondary' | 'destructive' | 'outline'> = {
  easy: 'secondary',
  medium: 'outline',
  hard: 'default',
  expert: 'destructive',
}

const columns: ColumnDef<QuestionListItem, unknown>[] = [
  {
    accessorKey: 'text',
    header: 'Question',
    cell: ({ row }) => (
      <div className="max-w-md">
        <div className="flex items-center gap-2">
          <p className="font-medium truncate">{row.getValue('text')}</p>
          {row.original.aiGenerated && (
            <Badge variant="outline" className="shrink-0 text-[10px] px-1.5 py-0 border-indigo-200 text-indigo-600">
              <Sparkles className="h-3 w-3 mr-0.5" />
              AI
            </Badge>
          )}
        </div>
        <div className="flex items-center gap-1.5 mt-1">
          <Badge variant="secondary" className="text-[10px]">
            {typeLabelMap[row.original.type] ?? row.original.type}
          </Badge>
        </div>
      </div>
    ),
  },
  {
    accessorKey: 'subject',
    header: 'Subject',
    cell: ({ row }) => (
      <span className="text-sm">{row.getValue('subject') ?? '—'}</span>
    ),
  },
  {
    accessorKey: 'topic',
    header: 'Topic',
    cell: ({ row }) => (
      <span className="text-sm">{row.getValue('topic') ?? '—'}</span>
    ),
  },
  {
    accessorKey: 'difficulty',
    header: 'Difficulty',
    cell: ({ row }) => {
      const difficulty = row.getValue('difficulty') as string
      return (
        <Badge variant={difficultyVariantMap[difficulty] ?? 'outline'}>
          {difficulty.charAt(0).toUpperCase() + difficulty.slice(1)}
        </Badge>
      )
    },
  },
  {
    accessorKey: 'marks',
    header: 'Marks',
    cell: ({ row }) => (
      <span className="text-sm">{row.getValue('marks')}</span>
    ),
  },
  {
    accessorKey: 'examUsageCount',
    header: 'Used In',
    cell: ({ row }) => (
      <span className="text-sm">{row.getValue('examUsageCount')} exams</span>
    ),
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => (
      <ViewButton href={`/question-bank/${row.original.id}`} />
    ),
  },
]

export default async function QuestionBankPage() {
  const { user } = await requireAuth()
  const role = user.role
  const schoolId = user.schoolId

  // Fetch live data from Supabase
  const data = await getQuestionBankData(role, user.id, schoolId)

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Question Bank</h1>
          <p className="text-sm text-muted-foreground">
            Browse, create, and manage questions for your exams.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <QuestionBankActions schoolId={schoolId} />
          <CreateQuestionDialog schoolId={schoolId} />
        </div>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Questions"
          value={data.stats.totalQuestions}
          icon={HelpCircle}
          description="In question bank"
        />
        <StatCard
          title="AI Generated"
          value={data.stats.aiGenerated}
          icon={Sparkles}
          description="AI-created questions"
        />
        <StatCard
          title="Subjects Covered"
          value={data.stats.subjectsCovered}
          icon={BookOpen}
          description="Unique subjects"
        />
        <StatCard
          title="Exam Usage"
          value={data.stats.examUsage}
          icon={FileText}
          description="Used in exams"
        />
      </div>

      {/* Data Table */}
      <Card>
        <CardHeader>
          <CardTitle>All Questions</CardTitle>
          <CardDescription>Browse and manage questions in the bank.</CardDescription>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={data.questions}
            searchKey="text"
            searchPlaceholder="Search questions..."
            emptyMessage="No questions found"
            emptyDescription="No questions have been created yet. Create your first question to get started."
          />
        </CardContent>
      </Card>
    </div>
  )
}
