'use client'

import { formatDistanceToNow } from 'date-fns'
import { type LucideIcon, Inbox } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ScrollArea } from '@/components/ui/scroll-area'

// ============================================================================
// ExamForge AI — Recent Activity List
// ============================================================================
// Displays a list of recent activity items with icon, description, and
// relative timestamp. Uses shadcn/ui Card with empty state fallback.
// ============================================================================

export interface ActivityItem {
  id: string
  icon: LucideIcon
  iconColor?: string
  title: string
  description: string
  timestamp: Date | string
}

export interface RecentActivityProps {
  items: ActivityItem[]
  title?: string
  className?: string
  maxHeight?: string
}

// ──────────────────────────────────────────────────────────────
// Default icon color palette
// ──────────────────────────────────────────────────────────────

const defaultIconColors = [
  'text-rose-500',
  'text-emerald-500',
  'text-amber-500',
  'text-violet-500',
  'text-cyan-500',
  'text-pink-500',
]

// ──────────────────────────────────────────────────────────────
// Recent Activity Component
// ──────────────────────────────────────────────────────────────

export function RecentActivity({
  items,
  title = 'Recent Activity',
  className,
  maxHeight = 'max-h-96',
}: RecentActivityProps) {
  return (
    <Card className={cn('flex flex-col', className)}>
      <CardHeader className="pb-3">
        <CardTitle className="text-base font-semibold">{title}</CardTitle>
      </CardHeader>
      <CardContent className="flex-1 p-0">
        {items.length === 0 ? (
          <EmptyState />
        ) : (
          <ScrollArea className={cn(maxHeight, 'overflow-y-auto')}>
            <div className="flex flex-col divide-y">
              {items.map((item, index) => {
                const Icon = item.icon
                const iconColor =
                  item.iconColor ?? defaultIconColors[index % defaultIconColors.length]
                const timestamp =
                  typeof item.timestamp === 'string'
                    ? new Date(item.timestamp)
                    : item.timestamp

                return (
                  <div
                    key={item.id}
                    className="flex items-start gap-3 px-6 py-3 hover:bg-muted/50 transition-colors"
                  >
                    <div
                      className={cn(
                        'mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-muted',
                        iconColor
                      )}
                    >
                      <Icon className="h-4 w-4" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium leading-tight truncate">
                        {item.title}
                      </p>
                      <p className="mt-0.5 text-xs text-muted-foreground line-clamp-2">
                        {item.description}
                      </p>
                    </div>
                    <time
                      className="shrink-0 text-[11px] text-muted-foreground whitespace-nowrap"
                      dateTime={timestamp.toISOString()}
                    >
                      {formatDistanceToNow(timestamp, { addSuffix: true })}
                    </time>
                  </div>
                )
              })}
            </div>
          </ScrollArea>
        )}
      </CardContent>
    </Card>
  )
}

// ──────────────────────────────────────────────────────────────
// Empty State
// ──────────────────────────────────────────────────────────────

function EmptyState() {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-6 text-center">
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-muted">
        <Inbox className="h-6 w-6 text-muted-foreground" />
      </div>
      <p className="mt-3 text-sm font-medium text-muted-foreground">
        No recent activity
      </p>
      <p className="mt-1 text-xs text-muted-foreground">
        Activity will appear here as you use the platform.
      </p>
    </div>
  )
}
