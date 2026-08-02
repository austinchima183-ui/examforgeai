import { NextResponse, type NextRequest } from 'next/server'
import { getAuthUser } from '@/lib/auth/require-auth'
import { globalSearch } from '@/lib/services/search-service'

// ============================================================================
// ExamForge AI — Global Search API Route
// ============================================================================
// Returns role-scoped search results. Requires authentication.
// Input validation: minimum 2 characters, maximum 100 characters.
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
    const query = searchParams.get('q') ?? ''

    // Input validation
    if (query.trim().length < 2) {
      return NextResponse.json({ results: [], total: 0, query })
    }

    if (query.length > 100) {
      return NextResponse.json(
        { error: 'Search query too long (max 100 characters)' },
        { status: 400 }
      )
    }

    const data = await globalSearch(query, user.id, user.schoolId, user.role)

    return NextResponse.json(data)
  } catch (error) {
    return NextResponse.json(
      { error: 'Search failed' },
      { status: 500 }
    )
  }
}
