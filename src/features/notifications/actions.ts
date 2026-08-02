// ============================================================================
// ExamForge AI — Notification Server Actions
// ============================================================================

'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function markNotificationReadAction(notificationId: string) {
  const supabase = await createClient()
  const { error } = await supabase
    .from('notifications')
    .update({ is_read: true, read_at: new Date().toISOString(), updated_at: new Date().toISOString() })
    .eq('id', notificationId)

  if (!error) {
    revalidatePath('/notifications')
  }

  return { error: error?.message ?? null }
}

export async function markAllNotificationsReadAction() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) return { error: 'Unauthorized' }

  const { error } = await supabase
    .from('notifications')
    .update({ is_read: true, read_at: new Date().toISOString(), updated_at: new Date().toISOString() })
    .eq('user_id', user.id)
    .eq('is_read', false)

  if (!error) {
    revalidatePath('/notifications')
  }

  return { error: error?.message ?? null }
}

export async function deleteNotificationAction(notificationId: string) {
  const supabase = await createClient()
  const { error } = await supabase
    .from('notifications')
    .delete()
    .eq('id', notificationId)

  if (!error) {
    revalidatePath('/notifications')
  }

  return { error: error?.message ?? null }
}
