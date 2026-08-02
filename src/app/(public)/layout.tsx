// ============================================================================
// ExamForge AI — Public Layout
// ============================================================================
// Layout for unauthenticated routes (login, register, forgot-password, etc.)
// Features a centered card with a gradient background and no navigation chrome.
// ============================================================================

export default function PublicLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-muted/50 p-4">
      {/* Skip navigation link */}
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:rounded-md focus:bg-primary focus:px-4 focus:py-2 focus:text-primary-foreground focus:outline-none focus:ring-2 focus:ring-ring"
      >
        Skip to main content
      </a>

      {/* Decorative background elements */}
      <div className="fixed inset-0 -z-10 overflow-hidden" aria-hidden="true">
        <div className="absolute -top-40 -right-40 h-80 w-80 rounded-full bg-primary/5 blur-3xl" />
        <div className="absolute -bottom-40 -left-40 h-80 w-80 rounded-full bg-primary/5 blur-3xl" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 h-96 w-96 rounded-full bg-primary/3 blur-3xl" />
      </div>

      {/* Content card */}
      <div className="w-full max-w-md">
        {/* Logo */}
        <header className="flex flex-col items-center mb-8">
          <div className="flex items-center gap-2 mb-2">
            <div className="h-10 w-10 rounded-lg bg-primary flex items-center justify-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                className="h-6 w-6 text-primary-foreground"
                aria-hidden="true"
              >
                <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" />
                <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" />
              </svg>
            </div>
            <span className="text-2xl font-bold tracking-tight">ExamForge AI</span>
          </div>
          <p className="text-sm text-muted-foreground text-center">
            AI-Powered Exam Creation &amp; Assessment Platform
          </p>
        </header>

        {/* Auth card */}
        <main id="main-content" className="bg-card rounded-xl border shadow-sm p-6 sm:p-8">
          {children}
        </main>

        {/* Footer */}
        <footer className="mt-6 text-center text-xs text-muted-foreground">
          &copy; {new Date().getFullYear()} ExamForge AI. All rights reserved.
        </footer>
      </div>
    </div>
  )
}
