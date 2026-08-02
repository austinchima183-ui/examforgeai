import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { getAnalyticsData } from '@/lib/services/analytics-service'

export async function GET(request: Request) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { searchParams } = new URL(request.url)
  const range = (searchParams.get('range') ?? '30d') as '7d' | '30d' | '90d' | '1y' | 'all'

  const { data: profile } = await supabase
    .from('profiles')
    .select('school_id, role')
    .eq('id', user.id)
    .single()

  const profileData = profile as { school_id: string | null; role: string } | null
  const role = (profileData?.role ?? 'student') as 'student' | 'teacher' | 'school_admin' | 'super_admin'
  const schoolId = profileData?.school_id ?? null

  const data = await getAnalyticsData(role, user.id, schoolId, range)

  return NextResponse.json(data)
}
