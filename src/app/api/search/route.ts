import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { globalSearch } from '@/lib/services/search-service'

export async function GET(request: Request) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { searchParams } = new URL(request.url)
  const query = searchParams.get('q') ?? ''

  if (query.trim().length < 2) {
    return NextResponse.json({ results: [], total: 0, query })
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('school_id, role')
    .eq('id', user.id)
    .single()

  const profileData = profile as { school_id: string | null; role: string } | null
  const role = profileData?.role ?? 'student'
  const schoolId = profileData?.school_id ?? null

  const data = await globalSearch(query, user.id, schoolId, role)

  return NextResponse.json(data)
}
