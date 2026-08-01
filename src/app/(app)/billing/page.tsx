import { CreditCard, Zap, Users, FileText, Download, CheckCircle, ArrowUpRight } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Progress } from '@/components/ui/progress'
import { Separator } from '@/components/ui/separator'

// ============================================================================
// ExamForge AI — Billing Page
// ============================================================================
// Server Component. Displays current subscription plan, usage stats,
// upgrade button, and invoice history.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

interface Invoice {
  id: string
  date: string
  amount: string
  status: 'paid' | 'pending' | 'failed'
  description: string
}

// ──────────────────────────────────────────────────────────────
// Mock Data
// ──────────────────────────────────────────────────────────────

const CURRENT_PLAN = {
  name: 'Professional',
  price: '$29.99',
  period: '/month',
  billingDate: 'Feb 15, 2024',
  features: [
    'Up to 500 students',
    'Unlimited exams',
    'AI question generation',
    'Advanced analytics',
    'Priority support',
    'Custom branding',
  ],
}

const USAGE = {
  students: { used: 342, limit: 500 },
  exams: { used: 87, limit: -1 }, // -1 = unlimited
  aiQuestions: { used: 1240, limit: 2000 },
  storage: { used: 4.2, limit: 10 }, // GB
}

const MOCK_INVOICES: Invoice[] = [
  {
    id: 'INV-2024-001',
    date: 'Jan 15, 2024',
    amount: '$29.99',
    status: 'paid',
    description: 'Professional Plan — Monthly',
  },
  {
    id: 'INV-2023-012',
    date: 'Dec 15, 2023',
    amount: '$29.99',
    status: 'paid',
    description: 'Professional Plan — Monthly',
  },
  {
    id: 'INV-2023-011',
    date: 'Nov 15, 2023',
    amount: '$29.99',
    status: 'paid',
    description: 'Professional Plan — Monthly',
  },
  {
    id: 'INV-2023-010',
    date: 'Oct 15, 2023',
    amount: '$29.99',
    status: 'paid',
    description: 'Professional Plan — Monthly',
  },
  {
    id: 'INV-2023-009',
    date: 'Sep 15, 2023',
    amount: '$14.99',
    status: 'paid',
    description: 'Starter Plan — Monthly (Upgrade partial)',
  },
]

// ──────────────────────────────────────────────────────────────
// Page Component
// ──────────────────────────────────────────────────────────────

export default function BillingPage() {
  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Billing</h1>
          <p className="text-sm text-muted-foreground">
            Manage your subscription, usage, and billing history.
          </p>
        </div>
        <Button variant="outline" className="gap-2">
          <CreditCard className="h-4 w-4" />
          Manage Payment Method
        </Button>
      </div>

      {/* Current Plan & Upgrade */}
      <div className="grid gap-4 lg:grid-cols-3">
        {/* Current Plan Card */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>Current Plan</CardTitle>
                <CardDescription>Your active subscription details.</CardDescription>
              </div>
              <Badge variant="default" className="gap-1">
                <Zap className="h-3 w-3" />
                {CURRENT_PLAN.name}
              </Badge>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-baseline gap-1">
                <span className="text-3xl font-bold">{CURRENT_PLAN.price}</span>
                <span className="text-sm text-muted-foreground">{CURRENT_PLAN.period}</span>
              </div>
              <p className="text-sm text-muted-foreground">
                Next billing date: <span className="font-medium text-foreground">{CURRENT_PLAN.billingDate}</span>
              </p>
              <Separator />
              <div className="space-y-2">
                <p className="text-sm font-medium">Included features:</p>
                <ul className="space-y-1.5">
                  {CURRENT_PLAN.features.map((feature) => (
                    <li key={feature} className="flex items-center gap-2 text-sm">
                      <CheckCircle className="h-4 w-4 text-emerald-600 shrink-0" />
                      {feature}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Upgrade Card */}
        <Card className="border-primary/20 bg-primary/5">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <ArrowUpRight className="h-5 w-5 text-primary" />
              Upgrade Plan
            </CardTitle>
            <CardDescription>Get more features and higher limits.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <p className="text-lg font-bold">Enterprise</p>
              <p className="text-sm text-muted-foreground">Unlimited everything</p>
              <div className="flex items-baseline gap-1 mt-2">
                <span className="text-2xl font-bold">$79.99</span>
                <span className="text-sm text-muted-foreground">/month</span>
              </div>
            </div>
            <ul className="space-y-1.5">
              <li className="flex items-center gap-2 text-sm">
                <CheckCircle className="h-4 w-4 text-primary shrink-0" />
                Unlimited students
              </li>
              <li className="flex items-center gap-2 text-sm">
                <CheckCircle className="h-4 w-4 text-primary shrink-0" />
                Unlimited AI questions
              </li>
              <li className="flex items-center gap-2 text-sm">
                <CheckCircle className="h-4 w-4 text-primary shrink-0" />
                50 GB storage
              </li>
              <li className="flex items-center gap-2 text-sm">
                <CheckCircle className="h-4 w-4 text-primary shrink-0" />
                Dedicated support
              </li>
            </ul>
            <Button className="w-full gap-2">
              <Zap className="h-4 w-4" />
              Upgrade to Enterprise
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Usage Stats */}
      <Card>
        <CardHeader>
          <CardTitle>Usage This Billing Period</CardTitle>
          <CardDescription>Track your resource usage against plan limits.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-6 sm:grid-cols-2">
            {/* Students */}
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="flex items-center gap-1.5">
                  <Users className="h-4 w-4 text-muted-foreground" />
                  Students
                </span>
                <span className="text-muted-foreground">
                  {USAGE.students.used} / {USAGE.students.limit}
                </span>
              </div>
              <Progress value={(USAGE.students.used / USAGE.students.limit) * 100} className="h-2" />
              <p className="text-xs text-muted-foreground">
                {(USAGE.students.limit - USAGE.students.used)} students remaining
              </p>
            </div>

            {/* AI Questions */}
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="flex items-center gap-1.5">
                  <Zap className="h-4 w-4 text-muted-foreground" />
                  AI Questions
                </span>
                <span className="text-muted-foreground">
                  {USAGE.aiQuestions.used.toLocaleString()} / {USAGE.aiQuestions.limit.toLocaleString()}
                </span>
              </div>
              <Progress value={(USAGE.aiQuestions.used / USAGE.aiQuestions.limit) * 100} className="h-2" />
              <p className="text-xs text-muted-foreground">
                {(USAGE.aiQuestions.limit - USAGE.aiQuestions.used).toLocaleString()} questions remaining
              </p>
            </div>

            {/* Exams */}
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="flex items-center gap-1.5">
                  <FileText className="h-4 w-4 text-muted-foreground" />
                  Exams Created
                </span>
                <span className="text-muted-foreground">
                  {USAGE.exams.used} / Unlimited
                </span>
              </div>
              <Progress value={100} className="h-2" />
              <p className="text-xs text-muted-foreground">
                Unlimited exams included in your plan
              </p>
            </div>

            {/* Storage */}
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="flex items-center gap-1.5">
                  <FileText className="h-4 w-4 text-muted-foreground" />
                  Storage
                </span>
                <span className="text-muted-foreground">
                  {USAGE.storage.used} GB / {USAGE.storage.limit} GB
                </span>
              </div>
              <Progress value={(USAGE.storage.used / USAGE.storage.limit) * 100} className="h-2" />
              <p className="text-xs text-muted-foreground">
                {(USAGE.storage.limit - USAGE.storage.used).toFixed(1)} GB remaining
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Invoice History */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Invoice History</CardTitle>
              <CardDescription>View and download past invoices.</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-0">
            {MOCK_INVOICES.map((invoice, index) => (
              <div key={invoice.id}>
                <div className="flex items-center justify-between py-3">
                  <div className="flex items-center gap-4">
                    <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-muted">
                      <FileText className="h-4 w-4 text-muted-foreground" />
                    </div>
                    <div>
                      <p className="text-sm font-medium">{invoice.description}</p>
                      <p className="text-xs text-muted-foreground">
                        {invoice.id} • {invoice.date}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Badge
                      variant={invoice.status === 'paid' ? 'default' : invoice.status === 'pending' ? 'secondary' : 'destructive'}
                    >
                      {invoice.status.charAt(0).toUpperCase() + invoice.status.slice(1)}
                    </Badge>
                    <span className="text-sm font-medium">{invoice.amount}</span>
                    <Button variant="ghost" size="icon" className="h-8 w-8">
                      <Download className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
                {index < MOCK_INVOICES.length - 1 && <Separator />}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
