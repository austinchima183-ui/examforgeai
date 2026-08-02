import { NextResponse, type NextRequest } from 'next/server'
import { getAuthUser } from '@/lib/auth/require-auth'
import { getReportsData } from '@/lib/services/reports-service'

// ============================================================================
// ExamForge AI — Reports API Route
// ============================================================================
// Returns role-scoped report data. Requires authentication.
// ============================================================================

export const dynamic = 'force-dynamic'

export async function GET(request: NextRequest) {
  const authResult = await getAuthUser()

  if (!authResult) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { user } = authResult

  try {
    const { searchParams } = new URL(request.url)
    const dateFrom = searchParams.get('from') ?? undefined
    const dateTo = searchParams.get('to') ?? undefined

    const data = await getReportsData(user.role, user.id, user.schoolId, dateFrom, dateTo)

    return NextResponse.json(data)
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch reports data' },
      { status: 500 }
    )
  }
}
