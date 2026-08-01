'use client'

import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { FileQuestion, Home, ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'

// ============================================================================
// ExamForge AI — 404 Not Found Page
// ============================================================================
// Professional 404 design with clear navigation back to the dashboard.
// ============================================================================

export default function NotFound() {
  const router = useRouter()

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background p-4">
      <div className="flex flex-col items-center gap-6 text-center">
        {/* Icon */}
        <div className="relative">
          <div className="flex h-20 w-20 items-center justify-center rounded-full bg-muted">
            <FileQuestion className="h-10 w-10 text-muted-foreground" />
          </div>
          <div className="absolute -top-1 -right-1 flex h-8 w-8 items-center justify-center rounded-full bg-primary text-xs font-bold text-primary-foreground">
            404
          </div>
        </div>

        {/* Message */}
        <div className="space-y-2">
          <h1 className="text-2xl font-bold tracking-tight">Page not found</h1>
          <p className="text-sm text-muted-foreground max-w-md">
            The page you&apos;re looking for doesn&apos;t exist or has been moved.
            Check the URL or navigate back to the dashboard.
          </p>
        </div>

        {/* Actions */}
        <div className="flex flex-col gap-3 sm:flex-row">
          <Button variant="outline" onClick={() => router.back()}>
            <ArrowLeft className="mr-2 h-4 w-4" />
            Go back
          </Button>
          <Button asChild>
            <Link href="/dashboard">
              <Home className="mr-2 h-4 w-4" />
              Dashboard
            </Link>
          </Button>
        </div>
      </div>
    </div>
  )
}
