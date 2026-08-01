'use client'

import { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { ScrollArea } from '@/components/ui/scroll-area'
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
} from 'lucide-react'

// ============================================================================
// ExamForge AI — Notifications Page
// ============================================================================
// Client component with list of notifications, mark as read,
// and filter by type.
// ============================================================================

type NotificationType = 'exam' | 'result' | 'system' | 'social' | 'reminder'
type NotificationPriority = 'low' | 'medium' | 'high'

interface Notification {
  id: string
  title: string
  description: string
  type: NotificationType
  priority: NotificationPriority
  read: boolean
  createdAt: string
}

// Placeholder data — in production, these would be fetched from Supabase
const INITIAL_NOTIFICATIONS: Notification[] = [
  {
    id: '1',
    title: 'Exam Published',
    description: 'Your "Mathematics Mid-Term" exam has been published and is now available to students.',
    type: 'exam',
    priority: 'high',
    read: false,
    createdAt: '10 minutes ago',
  },
  {
    id: '2',
    title: 'Results Available',
    description: 'Results for "Physics Chapter 4 Quiz" are now available for review.',
    type: 'result',
    priority: 'medium',
    read: false,
    createdAt: '1 hour ago',
  },
  {
    id: '3',
    title: 'System Update',
    description: 'ExamForge AI has been updated to version 2.5. Check out the new AI question generation features.',
    type: 'system',
    priority: 'low',
    read: false,
    createdAt: '3 hours ago',
  },
  {
    id: '4',
    title: 'New Student Enrolled',
    description: 'A new student, Alex Johnson, has been added to your SS2A class.',
    type: 'social',
    priority: 'medium',
    read: true,
    createdAt: '5 hours ago',
  },
  {
    id: '5',
    title: 'Exam Reminder',
    description: 'The "English Essay" exam is scheduled for tomorrow at 9:00 AM.',
    type: 'reminder',
    priority: 'high',
    read: false,
    createdAt: '1 day ago',
  },
  {
    id: '6',
    title: 'Assignment Submitted',
    description: '15 students have submitted their responses for the Biology assignment.',
    type: 'result',
    priority: 'medium',
    read: true,
    createdAt: '1 day ago',
  },
  {
    id: '7',
    title: 'AI Credits Low',
    description: 'Your AI generation credits are running low. Consider upgrading your plan.',
    type: 'system',
    priority: 'high',
    read: false,
    createdAt: '2 days ago',
  },
]

const TYPE_ICONS: Record<NotificationType, typeof Bell> = {
  exam: FileText,
  result: CheckCircle2,
  system: Settings,
  social: Users,
  reminder: AlertCircle,
}

const TYPE_COLORS: Record<NotificationType, string> = {
  exam: 'text-blue-600 bg-blue-50',
  result: 'text-green-600 bg-green-50',
  system: 'text-gray-600 bg-gray-50',
  social: 'text-purple-600 bg-purple-50',
  reminder: 'text-amber-600 bg-amber-50',
}

const TYPE_LABELS: Record<NotificationType, string> = {
  exam: 'Exams',
  result: 'Results',
  system: 'System',
  social: 'Social',
  reminder: 'Reminders',
}

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>(INITIAL_NOTIFICATIONS)
  const [filter, setFilter] = useState<'all' | NotificationType>('all')

  const filteredNotifications =
    filter === 'all'
      ? notifications
      : notifications.filter((n) => n.type === filter)

  const unreadCount = notifications.filter((n) => !n.read).length

  const markAsRead = (id: string) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, read: true } : n))
    )
  }

  const markAllAsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })))
  }

  const deleteNotification = (id: string) => {
    setNotifications((prev) => prev.filter((n) => n.id !== id))
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
            <Button variant="outline" size="sm" onClick={markAllAsRead}>
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
        <Select value={filter} onValueChange={(value) => setFilter(value as typeof filter)}>
          <SelectTrigger className="w-[180px]">
            <SelectValue placeholder="Filter by type" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Notifications</SelectItem>
            <SelectItem value="exam">Exams</SelectItem>
            <SelectItem value="result">Results</SelectItem>
            <SelectItem value="system">System</SelectItem>
            <SelectItem value="social">Social</SelectItem>
            <SelectItem value="reminder">Reminders</SelectItem>
          </SelectContent>
        </Select>
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
                ? 'You&apos;re all caught up! Check back later for new notifications.'
                : `No ${TYPE_LABELS[filter as NotificationType]?.toLowerCase() ?? ''} notifications found.`}
            </p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <div className="divide-y">
            {filteredNotifications.map((notification) => {
              const Icon = TYPE_ICONS[notification.type]
              const colorClass = TYPE_COLORS[notification.type]

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
                        {notification.createdAt}
                      </span>
                      <Badge variant="outline" className="text-[10px] px-1.5 py-0">
                        {TYPE_LABELS[notification.type]}
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
                        onClick={() => markAsRead(notification.id)}
                        title="Mark as read"
                      >
                        <CheckCheck className="h-4 w-4" />
                      </Button>
                    )}
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-muted-foreground hover:text-destructive"
                      onClick={() => deleteNotification(notification.id)}
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
