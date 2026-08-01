// ============================================================================
// ExamForge AI — School Server Actions
// ============================================================================

'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { z } from 'zod'

const createSchoolSchema = z.object({
  name: z.string().min(1, 'School name is required'),
  code: z.string().min(1, 'School code is required'),
  address: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  country: z.string().default('Nigeria'),
  phone: z.string().optional(),
  email: z.string().email().optional().or(z.literal('')),
  motto: z.string().optional(),
  school_type: z.string().optional(),
  educational_level: z.string().optional(),
})

export async function createSchoolAction(formData: FormData) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) return { error: 'Unauthorized' }

  const rawData = {
    name: formData.get('name') as string,
    code: formData.get('code') as string,
    address: formData.get('address') as string || undefined,
    city: formData.get('city') as string || undefined,
    state: formData.get('state') as string || undefined,
    country: formData.get('country') as string || 'Nigeria',
    phone: formData.get('phone') as string || undefined,
    email: formData.get('email') as string || undefined,
    motto: formData.get('motto') as string || undefined,
    school_type: formData.get('school_type') as string || undefined,
    educational_level: formData.get('educational_level') as string || undefined,
  }

  const validated = createSchoolSchema.safeParse(rawData)
  if (!validated.success) {
    return { error: validated.error.issues[0].message }
  }

  const { error } = await supabase
    .from('schools')
    .insert({
      ...validated.data,
      created_by: user.id,
      is_active: true,
    })

  if (!error) {
    revalidatePath('/schools')
  }

  return { error: error?.message ?? null }
}

export async function updateSchoolAction(id: string, formData: FormData) {
  const supabase = await createClient()

  const updates: Record<string, unknown> = { updated_at: new Date().toISOString() }

  const fields = ['name', 'code', 'address', 'city', 'state', 'country', 'phone', 'email', 'motto', 'school_type', 'educational_level', 'is_active']
  for (const field of fields) {
    const value = formData.get(field)
    if (value !== null) {
      if (field === 'is_active') {
        updates[field] = value === 'true'
      } else {
        updates[field] = value as string
      }
    }
  }

  const { error } = await supabase
    .from('schools')
    .update(updates)
    .eq('id', id)

  if (!error) {
    revalidatePath('/schools')
  }

  return { error: error?.message ?? null }
}

export async function deactivateSchoolAction(id: string) {
  const supabase = await createClient()
  const { error } = await supabase
    .from('schools')
    .update({ is_active: false, updated_at: new Date().toISOString() })
    .eq('id', id)

  if (!error) {
    revalidatePath('/schools')
  }

  return { error: error?.message ?? null }
}
