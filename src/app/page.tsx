import { redirect } from 'next/navigation'

// ============================================================================
// ExamForge AI — Root Page
// ============================================================================
// Redirects to the dashboard. The middleware handles auth checks
// and will redirect unauthenticated users to /login.
// ============================================================================

export default function HomePage() {
  redirect('/dashboard')
}
