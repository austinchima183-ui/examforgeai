import { requireAuth } from '@/lib/auth/require-auth'
import { CreditCard, Download, ArrowUpRight, CheckCircle2, Clock, AlertCircle, Receipt, Crown } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Progress } from '@/components/ui/progress'
import { Separator } from '@/components/ui/separator'
import { getBillingData } from '@/lib/services/billing-service'

export const dynamic = 'force-dynamic'

// ============================================================================
// ExamForge AI — Billing Page
// ============================================================================
// Server Component. Displays billing data from Supabase.
// No mock data. All plans, invoices, and usage are live.
// ============================================================================

const statusIconMap: Record<string, typeof CheckCircle2> = {
  successful: CheckCircle2,
  pending: Clock,
  failed: AlertCircle,
  refunded: ArrowUpRight,
}

const statusVariantMap: Record<string, 'default' | 'secondary' | 'destructive' | 'outline'> = {
  successful: 'default',
  pending: 'secondary',
  failed: 'destructive',
  refunded: 'outline',
  processing: 'secondary',
}

function formatCurrency(amount: number, currency: string = 'NGN'): string {
  return new Intl.NumberFormat('en-NG', {
    style: 'currency',
    currency: currency === 'NGN' ? 'NGN' : 'USD',
    minimumFractionDigits: 0,
  }).format(amount)
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

export default async function BillingPage() {
  const { user } = await requireAuth()

  // Fetch live billing data from Supabase
  const data = await getBillingData(user.id)

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Billing</h1>
        <p className="text-sm text-muted-foreground">
          Manage your subscription, view invoices, and track usage.
        </p>
      </div>

      {/* Current Plan & Upgrade */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Current Plan */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>Current Plan</CardTitle>
                <CardDescription>Your active subscription</CardDescription>
              </div>
              <Crown className="h-5 w-5 text-primary" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-semibold">{data.currentPlan?.name ?? 'Free'}</h3>
                  <p className="text-sm text-muted-foreground">
                    {formatCurrency(data.currentPlan?.price ?? 0, data.currentPlan?.currency ?? 'NGN')}/{data.currentPlan?.billingCycle ?? 'monthly'}
                  </p>
                </div>
                <Badge variant={data.currentPlan?.tier === 'free' ? 'secondary' : 'default'}>
                  {data.currentPlan?.tier?.toUpperCase() ?? 'FREE'}
                </Badge>
              </div>

              {data.currentPlan?.features && data.currentPlan.features.length > 0 && (
                <div className="space-y-2">
                  {data.currentPlan.features.map((feature, idx) => (
                    <div key={idx} className="flex items-center gap-2 text-sm">
                      <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
                      {feature}
                    </div>
                  ))}
                </div>
              )}

              {data.upcomingInvoice && (
                <div className="text-sm text-muted-foreground">
                  Next billing: {formatDate(data.upcomingInvoice.date)} — {formatCurrency(data.upcomingInvoice.amount, data.upcomingInvoice.currency)}
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Upgrade Card */}
        <Card className="border-primary/50">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>Upgrade Plan</CardTitle>
                <CardDescription>Get more features and capacity</CardDescription>
              </div>
              <ArrowUpRight className="h-5 w-5 text-primary" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <h3 className="text-lg font-semibold">Professional</h3>
                <p className="text-sm text-muted-foreground">
                  Unlock unlimited exams, AI questions, and premium support.
                </p>
              </div>
              <Button className="w-full" asChild>
                <Link href="/billing/plans"><ArrowUpRight className="h-4 w-4 mr-2" />Upgrade Now</Link>
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Usage Stats */}
      <Card>
        <CardHeader>
          <CardTitle>Usage</CardTitle>
          <CardDescription>Current billing period usage</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-6">
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span>Students</span>
                <span className="text-muted-foreground">{data.usage.studentsUsed} / {data.usage.studentsLimit === 999 ? 'Unlimited' : data.usage.studentsLimit}</span>
              </div>
              <Progress value={data.usage.studentsLimit === 999 ? 10 : (data.usage.studentsUsed / data.usage.studentsLimit) * 100} className="h-2" />
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span>AI Questions</span>
                <span className="text-muted-foreground">{data.usage.aiQuestionsUsed} / {data.usage.aiQuestionsLimit === 999 ? 'Unlimited' : data.usage.aiQuestionsLimit}</span>
              </div>
              <Progress value={data.usage.aiQuestionsLimit === 999 ? 10 : (data.usage.aiQuestionsUsed / data.usage.aiQuestionsLimit) * 100} className="h-2" />
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span>Exams</span>
                <span className="text-muted-foreground">{data.usage.examsUsed} / {data.usage.examsLimit === 999 ? 'Unlimited' : data.usage.examsLimit}</span>
              </div>
              <Progress value={data.usage.examsLimit === 999 ? 10 : (data.usage.examsUsed / data.usage.examsLimit) * 100} className="h-2" />
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span>Storage</span>
                <span className="text-muted-foreground">{data.usage.storageUsedGb} / {data.usage.storageLimitGb} GB</span>
              </div>
              <Progress value={(data.usage.storageUsedGb / data.usage.storageLimitGb) * 100} className="h-2" />
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
              <CardDescription>Your payment history and receipts</CardDescription>
            </div>
            <Receipt className="h-5 w-5 text-muted-foreground" />
          </div>
        </CardHeader>
        <CardContent>
          {data.invoices.length > 0 ? (
            <div className="divide-y">
              {data.invoices.map((invoice) => {
                const StatusIcon = statusIconMap[invoice.status] ?? Clock
                return (
                  <div key={invoice.id} className="flex items-center justify-between py-3">
                    <div className="flex items-center gap-3">
                      <div className="h-9 w-9 rounded-lg bg-muted flex items-center justify-center">
                        <StatusIcon className="h-4 w-4 text-muted-foreground" />
                      </div>
                      <div>
                        <p className="text-sm font-medium">{invoice.description}</p>
                        <p className="text-xs text-muted-foreground">{formatDate(invoice.date)}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-sm font-medium">{formatCurrency(invoice.amount, invoice.currency)}</span>
                      <Badge variant={statusVariantMap[invoice.status] ?? 'secondary'}>
                        {invoice.status.charAt(0).toUpperCase() + invoice.status.slice(1)}
                      </Badge>
                      <a href={`/api/billing/invoice/${invoice.id}`} target="_blank" rel="noopener noreferrer">
                        <Button variant="ghost" size="sm" className="h-8">
                          <Download className="h-4 w-4" />
                        </Button>
                      </a>
                    </div>
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="p-8 text-center">
              <p className="text-sm text-muted-foreground">No invoices yet. Invoices will appear here once you make a payment.</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
