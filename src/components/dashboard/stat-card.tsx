'use client'

import { type LucideIcon, TrendingUp, TrendingDown, Minus } from 'lucide-react'
import { motion } from 'framer-motion'
import { cn } from '@/lib/utils'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

// ============================================================================
// ExamForge AI — Stat Card Component
// ============================================================================
// Animated stat card with Framer Motion entrance, trend indicator, and
// responsive layout. Uses shadcn/ui Card with color-coded trends.
// ============================================================================

export type TrendDirection = 'up' | 'down' | 'neutral'

export interface StatCardProps {
  title: string
  value: string | number
  description?: string
  icon: LucideIcon
  trend?: TrendDirection
  trendValue?: string
  className?: string
}

// ──────────────────────────────────────────────────────────────
// Trend Color Mapping
// ──────────────────────────────────────────────────────────────

const trendConfig: Record<
  TrendDirection,
  { color: string; bgColor: string; icon: LucideIcon }
> = {
  up: {
    color: 'text-emerald-600 dark:text-emerald-400',
    bgColor: 'bg-emerald-50 dark:bg-emerald-950/40',
    icon: TrendingUp,
  },
  down: {
    color: 'text-red-600 dark:text-red-400',
    bgColor: 'bg-red-50 dark:bg-red-950/40',
    icon: TrendingDown,
  },
  neutral: {
    color: 'text-amber-600 dark:text-amber-400',
    bgColor: 'bg-amber-50 dark:bg-amber-950/40',
    icon: Minus,
  },
}

// ──────────────────────────────────────────────────────────────
// Stat Card Component
// ──────────────────────────────────────────────────────────────

export function StatCard({
  title,
  value,
  description,
  icon: Icon,
  trend = 'neutral',
  trendValue,
  className,
}: StatCardProps) {
  const trendInfo = trendConfig[trend]
  const TrendIcon = trendInfo.icon

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: 'easeOut' }}
      whileHover={{ y: -2, transition: { duration: 0.2 } }}
    >
      <Card className={cn('relative overflow-hidden', className)}>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">
            {title}
          </CardTitle>
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/10">
            <Icon className="h-4 w-4 text-primary" />
          </div>
        </CardHeader>
        <CardContent>
          <div className="flex items-baseline gap-2">
            <span className="text-2xl font-bold tracking-tight">{value}</span>
            {trendValue && (
              <div
                className={cn(
                  'inline-flex items-center gap-0.5 rounded-full px-2 py-0.5 text-xs font-medium',
                  trendInfo.bgColor,
                  trendInfo.color
                )}
              >
                <TrendIcon className="h-3 w-3" />
                {trendValue}
              </div>
            )}
          </div>
          {description && (
            <p className="mt-1 text-xs text-muted-foreground">{description}</p>
          )}
        </CardContent>
      </Card>
    </motion.div>
  )
}
