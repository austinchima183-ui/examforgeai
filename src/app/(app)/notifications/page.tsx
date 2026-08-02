'use client'

import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Bell,
  FileText,
  CheckCircle2,
  AlertCircle,
  Info,
  Users,
  Settings,
  Trash2,
  CheckCheck,
  Filter,
  DollarSign,
  Sparkles,
  GraduationCap,
} from 'lucide-react'
import { markNotificationReadAction, markAllNotificationsReadAction, deleteNotificationAction } from '@/features/notifications/actions'
import type { NotificationRow } from '@/lib/supabase/types'

// ============================================================================
// ExamForge AI — Notifications Page
// ============================================================================
// Client component with real Supabase Realtime subscriptions.
// No polling — uses onPostgresChange for live updates.
// ============================================================================

type NotificationType = 'exam_reminder' | 'exam_result' | 'assignment' | 'announcement' | 'message' | 'subscription' | 'payment' | 'system' | 'ai_generation' | 'marketplace' | 'enrollment'

interface DisplayNotification {
  id: string
  title: string
  description: string
  type: string
  priority: string | null
  read: boolean
  createdAt: string
  actionUrl: string | null
}

const TYPE_ICONS: Record<string, typeof Bell> = {
  exam_reminder: FileText,
  exam_result: CheckCircle2,
  assignment: FileText,
  announcement: Info,
  message: Users,
  subscription: Settings,
  payment: DollarSign,
  system: Settings,
  ai_generation: Sparkles,
  marketplace: GraduationCap,
  enrollment: Users,
}

const TYPE_COLORS: Record<string, string> = {
  exam_reminder: 'text-blue-600 bg-blue-50',
  exam_result: 'text-green-600 bg-green-50',
  assignment: 'text-blue-600 bg-blue-50',
  announcement: 'text-gray-600 bg-gray-50',
  message: 'text-purple-600 bg-purple-50',
  subscription: 'text-amber-600 bg-amber-50',
  payment: 'text-green-600 bg-green-50',
  system: 'text-gray-600 bg-gray-50',
  ai_generation: 'text-indigo-600 bg-indigo-50',
  marketplace: 'text-pink-600 bg-pink-50',
  enrollment: 'text-teal-600 bg-teal-50',
}

const TYPE_LABELS: Record<string, string> = {
  exam_reminder: 'Exams',
  exam_result: 'Results',
  assignment: 'Assignment',
  announcement: 'Announcement',
  message: 'Messages',
  subscription: 'Subscription',
  payment: 'Payment',
  system: 'System',
  ai_generation: 'AI',
  marketplace: 'Marketplace',
  enrollment: 'Enrollment',
}

function formatRelativeTime(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMs / 3600000)
  const diffDays = Math.floor(diffMs / 86400000)

  if (diffMins < 1) return 'Just now'
  if (diffMins < 60) return `${diffMins}m ago`
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays < 7) return `${diffDays}d ago`
  return date.toLocaleDateString()
}

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<DisplayNotification[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState<'all' | string>('all')

  // Fetch initial notifications from Supabase
  const fetchNotifications = useCallback(async () => {
    const supabase = createClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(50)

    if (error) {
      console.error('Error fetching notifications:', error)
      setLoading(false)
      return
    }

    const items: DisplayNotification[] = ((data as NotificationRow[] | null) ?? []).map(n => ({
      id: n.id,
      title: n.title,
      description: n.body,
      type: n.type,
      priority: n.priority,
      read: n.is_read,
      createdAt: n.created_at,
      actionUrl: n.action_url,
    }))

    setNotifications(items)
    setLoading(false)
  }, [])

  // Subscribe to realtime notifications
  useEffect(() => {
    let cancelled = false
    let channel: ReturnType<ReturnType<typeof createClient>['channel']> | null = null

    async function setup() {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      if (!user || cancelled) return

      // Fetch initial data
      const { data, error } = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(50)

      if (cancelled) return

      if (error) {
        setLoading(false)
        return
      }

      const items: DisplayNotification[] = ((data as NotificationRow[] | null) ?? []).map(n => ({
        id: n.id,
        title: n.title,
        description: n.body,
        type: n.type,
        priority: n.priority,
        read: n.is_read,
        createdAt: n.created_at,
        actionUrl: n.action_url,
      }))

      setNotifications(items)
      setLoading(false)

      // Subscribe to realtime notifications (filtered by user_id)
      channel = supabase
        .channel('notifications-realtime')
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: 'notifications',
            filter: `user_id=eq.${user.id}`,
          },
          (payload: { new: NotificationRow }) => {
            const newNotification = payload.new
            // Deduplication: skip if already in the list
            setNotifications(prev => {
              if (prev.some(n => n.id === newNotification.id)) return prev
              const display: DisplayNotification = {
                id: newNotification.id,
                title: newNotification.title,
                description: newNotification.body,
                type: newNotification.type,
                priority: newNotification.priority,
                read: newNotification.is_read,
                createdAt: newNotification.created_at,
                actionUrl: newNotification.action_url,
              }
              return [display, ...prev]
            })
          }
        )
        .on(
          'postgres_changes',
          {
            event: 'UPDATE',
            schema: 'public',
            table: 'notifications',
            filter: `user_id=eq.${user.id}`,
          },
          (payload: { new: NotificationRow }) => {
            const updated = payload.new
            setNotifications(prev =>
              prev.map(n =>
                n.id === updated.id
                  ? {
                      ...n,
                      read: updated.is_read,
                      priority: updated.priority,
                    }
                  : n
              )
            )
          }
        )
        .on(
          'postgres_changes',
          {
            event: 'DELETE',
            schema: 'public',
            table: 'notifications',
            filter: `user_id=eq.${user.id}`,
          },
          (payload: { old: { id: string } }) => {
            setNotifications(prev => prev.filter(n => n.id !== payload.old.id))
          }
        )
        .subscribe((status: string) => {
          if (status === 'CHANNEL_ERROR' || status === 'CLOSED') {
            // Supabase will attempt to reconnect automatically
          }
        })
    }

    setup()

    return () => {
      cancelled = true
      if (channel) {
        const supabase = createClient()
        supabase.removeChannel(channel)
      }
    }
  }, [fetchNotifications])

  const filteredNotifications =
    filter === 'all'
      ? notifications
      : notifications.filter((n) => n.type === filter)

  const unreadCount = notifications.filter((n) => !n.read).length

  const handleMarkAsRead = async (id: string) => {
    // Optimistic update
    setNotifications(prev =>
      prev.map(n => (n.id === id ? { ...n, read: true } : n))
    )
    await markNotificationReadAction(id)
  }

  const handleMarkAllAsRead = async () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })))
    await markAllNotificationsReadAction()
  }

  const handleDelete = async (id: string) => {
    // Optimistic update
    setNotifications(prev => prev.filter(n => n.id !== id))
    await deleteNotificationAction(id)
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-center p-12">
          <div className="animate-spin h-6 w-6 border-2 border-primary border-t-transparent rounded-full" />
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Notifications</h1>
          <p className="text-muted-foreground mt-1">
            Stay updated with your latest activities and alerts.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {unreadCount > 0 && (
            <Button variant="outline" size="sm" onClick={handleMarkAllAsRead}>
              <CheckCheck className="h-4 w-4 mr-1" />
              Mark all read
            </Button>
          )}
          <Badge variant="secondary">
            {unreadCount} unread
          </Badge>
        </div>
      </div>

      {/* Filter */}
      <div className="flex items-center gap-2">
        <Filter className="h-4 w-4 text-muted-foreground" />
        <Select value={filter} onValueChange={setFilter}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Filter by type" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Notifications</SelectItem>
            <SelectItem value="exam_reminder">Exams</SelectItem>
            <SelectItem value="exam_result">Results</SelectItem>
            <SelectItem value="system">System</SelectItem>
            <SelectItem value="message">Messages</SelectItem>
            <SelectItem value="payment">Payment</SelectItem>
            <SelectItem value="ai_generation">AI</SelectItem>
            <SelectItem value="marketplace">Marketplace</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Realtime indicator */}
      <div className="flex items-center gap-2 text-xs text-muted-foreground">
        <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
        Live — receiving updates in real-time
      </div>

      {/* Notifications List */}
      {filteredNotifications.length === 0 ? (
        <Card>
          <CardContent className="p-8 text-center">
            <div className="flex justify-center mb-4">
              <div className="h-16 w-16 rounded-full bg-muted flex items-center justify-center">
                <Bell className="h-8 w-8 text-muted-foreground" />
              </div>
            </div>
            <h3 className="text-lg font-medium">No notifications</h3>
            <p className="text-sm text-muted-foreground mt-1">
              {filter === 'all'
                ? "You're all caught up! New notifications will appear here in real-time."
                : `No ${TYPE_LABELS[filter]?.toLowerCase() ?? ''} notifications found.`}
            </p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <div className="divide-y">
            {filteredNotifications.map((notification) => {
              const Icon = TYPE_ICONS[notification.type] ?? Bell
              const colorClass = TYPE_COLORS[notification.type] ?? 'text-gray-600 bg-gray-50'

              return (
                <div
                  key={notification.id}
                  className={`flex items-start gap-3 p-4 transition-colors ${
                    !notification.read ? 'bg-muted/30' : ''
                  }`}
                >
                  <div className={`h-9 w-9 rounded-lg flex items-center justify-center shrink-0 ${colorClass}`}>
                    <Icon className="h-4 w-4" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <h4 className="text-sm font-medium truncate">
                        {notification.title}
                      </h4>
                      {!notification.read && (
                        <div className="h-2 w-2 rounded-full bg-primary shrink-0" />
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground mt-0.5 line-clamp-2">
                      {notification.description}
                    </p>
                    <div className="flex items-center gap-2 mt-1.5">
                      <span className="text-xs text-muted-foreground">
                        {formatRelativeTime(notification.createdAt)}
                      </span>
                      <Badge variant="outline" className="text-[10px] px-1.5 py-0">
                        {TYPE_LABELS[notification.type] ?? notification.type}
                      </Badge>
                      {notification.priority === 'high' && (
                        <Badge variant="destructive" className="text-[10px] px-1.5 py-0">
                          High
                        </Badge>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-1 shrink-0">
                    {!notification.read && (
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8"
                        onClick={() => handleMarkAsRead(notification.id)}
                        title="Mark as read"
                      >
                        <CheckCheck className="h-4 w-4" />
                      </Button>
                    )}
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-muted-foreground hover:text-destructive"
                      onClick={() => handleDelete(notification.id)}
                      title="Delete notification"
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              )
            })}
          </div>
        </Card>
      )}
    </div>
  )
}
