import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { getReportsData } from '@/lib/services/reports-service'

export async function GET(request: Request) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { searchParams } = new URL(request.url)
  const dateFrom = searchParams.get('from') ?? undefined
  const dateTo = searchParams.get('to') ?? undefined

  const { data: profile } = await supabase
    .from('profiles')
    .select('school_id, role')
    .eq('id', user.id)
    .single()

  const profileData = profile as { school_id: string | null; role: string } | null
  const role = profileData?.role ?? 'student'
  const schoolId = profileData?.school_id ?? null

  const data = await getReportsData(role, user.id, schoolId, dateFrom, dateTo)

  return NextResponse.json(data)
}
