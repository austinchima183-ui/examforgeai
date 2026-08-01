import { createClient } from '@/lib/supabase/server'
import { NextResponse, type NextRequest } from 'next/server'

// ============================================================================
// ExamForge AI — Health Check API Route
// ============================================================================
// Verifies backend connectivity. Replaces the placeholder "Hello, world!".
// ============================================================================

export async function GET() {
  const startTime = Date.now()

  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    // Test database connectivity
    const { error: dbError } = await supabase
      .from('profiles')
      .select('id', { count: 'exact', head: true })
      .limit(1)

    const responseTime = Date.now() - startTime

    return NextResponse.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      responseTimeMs: responseTime,
      services: {
        database: dbError ? 'degraded' : 'healthy',
        auth: user ? 'authenticated' : 'anonymous',
      },
      version: process.env.npm_package_version ?? '1.0.0',
    })
  } catch (error) {
    return NextResponse.json(
      {
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 503 }
    )
  }
}
