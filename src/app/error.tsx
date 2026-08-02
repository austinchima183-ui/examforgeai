'use client'

import { useEffect } from 'react'
import { AlertTriangle, RotateCw } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { logger } from '@/lib/utils/logger'

// ============================================================================
// ExamForge AI — Global Error Boundary
// ============================================================================
// Client component that catches unexpected errors at the root level.
// Uses the enterprise logger instead of console.error.
// ============================================================================

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // Report to enterprise logger (structured, sanitized)
    logger.error('Unhandled client error', error, {
      digest: error.digest,
      component: 'GlobalErrorBoundary',
    })
  }, [error])

  return (
    <div className="flex min-h-screen items-center justify-center bg-background p-4" role="alert" aria-live="assertive">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center pb-2">
          <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-destructive/10" aria-hidden="true">
            <AlertTriangle className="h-7 w-7 text-destructive" />
          </div>
          <CardTitle className="mt-4 text-xl">Something went wrong</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col items-center gap-4 text-center">
          <p className="text-sm text-muted-foreground">
            An unexpected error occurred. We&apos;ve been notified and are working on
            fixing the issue. Please try again.
          </p>
          {error.digest && (
            <p className="text-xs text-muted-foreground">
              Error ID: {error.digest}
            </p>
          )}
          <Button onClick={reset} className="mt-2">
            <RotateCw className="mr-2 h-4 w-4" aria-hidden="true" />
            Try again
          </Button>
        </CardContent>
      </Card>
    </div>
  )
}
