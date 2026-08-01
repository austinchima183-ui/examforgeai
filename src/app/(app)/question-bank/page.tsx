'use client'

import { type ColumnDef } from '@tanstack/react-table'
import {
  HelpCircle,
  Plus,
  Upload,
  Download,
  BookOpen,
  Tag,
  Layers,
} from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { DataTable } from '@/components/tables/data-table'
import { StatCard } from '@/components/dashboard/stat-card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

// ============================================================================
// ExamForge AI — Question Bank Page
// ============================================================================
// Server Component. Displays a list of questions with subject/topic/type
// filters, create question button, and import/export buttons.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

type QuestionType = 'multiple_choice' | 'true_false' | 'short_answer' | 'essay' | 'fill_in_blank'
type DifficultyLevel = 'easy' | 'medium' | 'hard' | 'expert'

interface Question {
  id: string
  text: string
  subject: string
  topic: string
  type: QuestionType
  difficulty: DifficultyLevel
  marks: number
  examUsageCount: number
  aiGenerated: boolean
  createdAt: string
}

// ──────────────────────────────────────────────────────────────
// Mock Data
// ──────────────────────────────────────────────────────────────

const MOCK_QUESTIONS: Question[] = [
  {
    id: '1',
    text: 'What is the derivative of f(x) = x² + 3x + 2?',
    subject: 'Mathematics',
    topic: 'Calculus',
    type: 'multiple_choice',
    difficulty: 'medium',
    marks: 5,
    examUsageCount: 12,
    aiGenerated: true,
    createdAt: '2024-01-15T10:00:00Z',
  },
  {
    id: '2',
    text: 'State Newton\'s third law of motion.',
    subject: 'Physics',
    topic: 'Laws of Motion',
    type: 'short_answer',
    difficulty: 'easy',
    marks: 3,
    examUsageCount: 8,
    aiGenerated: false,
    createdAt: '2024-01-14T08:30:00Z',
  },
  {
    id: '3',
    text: 'Explain the process of photosynthesis and its importance to the ecosystem.',
    subject: 'Biology',
    topic: 'Photosynthesis',
    type: 'essay',
    difficulty: 'hard',
    marks: 15,
    examUsageCount: 5,
    aiGenerated: false,
    createdAt: '2024-01-12T14:00:00Z',
  },
  {
    id: '4',
    text: 'The chemical formula for water is H₂O.',
    subject: 'Chemistry',
    topic: 'Chemical Formulae',
    type: 'true_false',
    difficulty: 'easy',
    marks: 2,
    examUsageCount: 20,
    aiGenerated: true,
    createdAt: '2024-01-10T09:00:00Z',
  },
  {
    id: '5',
    text: 'The capital of Nigeria is _____.',
    subject: 'Government',
    topic: 'Nigerian Government',
    type: 'fill_in_blank',
    difficulty: 'easy',
    marks: 2,
    examUsageCount: 15,
    aiGenerated: true,
    createdAt: '2024-01-08T11:00:00Z',
  },
  {
    id: '6',
    text: 'Discuss the impact of inflation on the purchasing power of consumers in developing economies.',
    subject: 'Economics',
    topic: 'Inflation',
    type: 'essay',
    difficulty: 'expert',
    marks: 20,
    examUsageCount: 3,
    aiGenerated: false,
    createdAt: '2024-01-05T16:00:00Z',
  },
  {
    id: '7',
    text: 'Which of the following is a vector quantity?',
    subject: 'Physics',
    topic: 'Vectors',
    type: 'multiple_choice',
    difficulty: 'medium',
    marks: 4,
    examUsageCount: 10,
    aiGenerated: true,
    createdAt: '2024-01-03T13:00:00Z',
  },
  {
    id: '8',
    text: 'Solve the quadratic equation: x² - 5x + 6 = 0',
    subject: 'Mathematics',
    topic: 'Quadratic Equations',
    type: 'short_answer',
    difficulty: 'medium',
    marks: 5,
    examUsageCount: 7,
    aiGenerated: false,
    createdAt: '2024-01-02T10:00:00Z',
  },
]

// ──────────────────────────────────────────────────────────────
// Column Definitions
// ──────────────────────────────────────────────────────────────

const typeLabelMap: Record<QuestionType, string> = {
  multiple_choice: 'Multiple Choice',
  true_false: 'True/False',
  short_answer: 'Short Answer',
  essay: 'Essay',
  fill_in_blank: 'Fill in Blank',
}

const difficultyConfig: Record<DifficultyLevel, { variant: 'default' | 'secondary' | 'destructive' | 'outline'; label: string }> = {
  easy: { variant: 'secondary', label: 'Easy' },
  medium: { variant: 'default', label: 'Medium' },
  hard: { variant: 'outline', label: 'Hard' },
  expert: { variant: 'destructive', label: 'Expert' },
}

const columns: ColumnDef<Question, unknown>[] = [
  {
    accessorKey: 'text',
    header: 'Question',
    cell: ({ row }) => (
      <div className="max-w-[300px]">
        <p className="font-medium truncate">{row.getValue('text')}</p>
        <div className="flex items-center gap-1.5 mt-1">
          <Badge variant="outline" className="text-[10px]">
            {row.original.type === 'multiple_choice' ? 'MCQ' : typeLabelMap[row.original.type]}
          </Badge>
          {row.original.aiGenerated && (
            <Badge variant="secondary" className="text-[10px]">AI</Badge>
          )}
        </div>
      </div>
    ),
  },
  {
    accessorKey: 'subject',
    header: 'Subject',
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <BookOpen className="h-3.5 w-3.5 text-muted-foreground" />
        {row.getValue('subject')}
      </div>
    ),
  },
  {
    accessorKey: 'topic',
    header: 'Topic',
    cell: ({ row }) => (
      <div className="flex items-center gap-1.5 text-sm">
        <Tag className="h-3.5 w-3.5 text-muted-foreground" />
        {row.getValue('topic')}
      </div>
    ),
  },
  {
    accessorKey: 'difficulty',
    header: 'Difficulty',
    cell: ({ row }) => {
      const difficulty = row.getValue('difficulty') as DifficultyLevel
      const config = difficultyConfig[difficulty]
      return <Badge variant={config.variant}>{config.label}</Badge>
    },
  },
  {
    accessorKey: 'marks',
    header: 'Marks',
    cell: ({ row }) => (
      <span className="text-sm font-medium">{row.getValue('marks')}</span>
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

export default function QuestionBankPage() {
  const totalQuestions = MOCK_QUESTIONS.length
  const aiGenerated = MOCK_QUESTIONS.filter((q) => q.aiGenerated).length
  const subjects = new Set(MOCK_QUESTIONS.map((q) => q.subject)).size
  const totalExams = MOCK_QUESTIONS.reduce((sum, q) => sum + q.examUsageCount, 0)

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
          <Button variant="outline" className="gap-2">
            <Upload className="h-4 w-4" />
            Import
          </Button>
          <Button variant="outline" className="gap-2">
            <Download className="h-4 w-4" />
            Export
          </Button>
          <Button className="gap-2">
            <Plus className="h-4 w-4" />
            Create Question
          </Button>
        </div>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Questions"
          value={totalQuestions}
          icon={HelpCircle}
          trend="up"
          trendValue="+24%"
          description="In the question bank"
        />
        <StatCard
          title="AI Generated"
          value={aiGenerated}
          icon={Layers}
          trend="up"
          trendValue="+35%"
          description="Created by AI"
        />
        <StatCard
          title="Subjects Covered"
          value={subjects}
          icon={BookOpen}
          trend="neutral"
          trendValue="6"
          description="Active subjects"
        />
        <StatCard
          title="Exam Usage"
          value={totalExams}
          icon={Tag}
          trend="up"
          trendValue="+18%"
          description="Total question uses"
        />
      </div>

      {/* Data Table */}
      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <CardTitle>All Questions</CardTitle>
              <CardDescription>Browse and manage questions in the bank.</CardDescription>
            </div>
            <div className="flex items-center gap-2">
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[160px]">
                  <SelectValue placeholder="Filter by subject" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Subjects</SelectItem>
                  <SelectItem value="math">Mathematics</SelectItem>
                  <SelectItem value="physics">Physics</SelectItem>
                  <SelectItem value="chemistry">Chemistry</SelectItem>
                  <SelectItem value="biology">Biology</SelectItem>
                  <SelectItem value="english">English</SelectItem>
                  <SelectItem value="economics">Economics</SelectItem>
                  <SelectItem value="government">Government</SelectItem>
                </SelectContent>
              </Select>
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[160px]">
                  <SelectValue placeholder="Filter by type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Types</SelectItem>
                  <SelectItem value="mcq">Multiple Choice</SelectItem>
                  <SelectItem value="tf">True/False</SelectItem>
                  <SelectItem value="short">Short Answer</SelectItem>
                  <SelectItem value="essay">Essay</SelectItem>
                  <SelectItem value="fill">Fill in Blank</SelectItem>
                </SelectContent>
              </Select>
              <Select defaultValue="all">
                <SelectTrigger className="h-9 w-[150px]">
                  <SelectValue placeholder="Filter by difficulty" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Levels</SelectItem>
                  <SelectItem value="easy">Easy</SelectItem>
                  <SelectItem value="medium">Medium</SelectItem>
                  <SelectItem value="hard">Hard</SelectItem>
                  <SelectItem value="expert">Expert</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={MOCK_QUESTIONS}
            searchKey="text"
            searchPlaceholder="Search questions..."
            emptyMessage="No questions found"
            emptyDescription="No questions match your criteria. Try creating a new question."
          />
        </CardContent>
      </Card>
    </div>
  )
}
