import type { Metadata, Viewport } from 'next'
import { Inter } from 'next/font/google'
import { ThemeProvider } from 'next-themes'
import { Toaster } from '@/components/ui/sonner'
import { SupabaseProvider } from '@/lib/hooks/use-supabase'
import { QueryProvider } from '@/lib/hooks/use-query-provider'
import './globals.css'

// ============================================================================
// ExamForge AI — Root Layout
// ============================================================================
// Wraps the entire application with required providers:
//   - ThemeProvider (next-themes for light/dark mode)
//   - SupabaseProvider (browser Supabase client)
//   - QueryProvider (TanStack React Query)
//   - Toaster (sonner for toast notifications)
// ============================================================================

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
})

// ──────────────────────────────────────────────────────────────
// Metadata
// ──────────────────────────────────────────────────────────────

export const metadata: Metadata = {
  title: {
    default: 'ExamForge AI',
    template: '%s | ExamForge AI',
  },
  description:
    'AI-powered exam creation, CBT engine, and educational platform for teachers, students, and school administrators.',
  keywords: [
    'ExamForge',
    'AI',
    'exam',
    'CBT',
    'education',
    'teacher',
    'student',
    'school',
    'assessment',
    'question bank',
  ],
  authors: [{ name: 'ExamForge AI Team' }],
  icons: {
    icon: '/favicon.ico',
  },
  openGraph: {
    title: 'ExamForge AI',
    description:
      'AI-powered exam creation, CBT engine, and educational platform.',
    siteName: 'ExamForge AI',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'ExamForge AI',
    description:
      'AI-powered exam creation, CBT engine, and educational platform.',
  },
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#0a0a0a' },
  ],
}

// ──────────────────────────────────────────────────────────────
// Root Layout Component
// ──────────────────────────────────────────────────────────────

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={inter.variable}
    >
      <body className="font-sans antialiased bg-background text-foreground">
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <SupabaseProvider>
            <QueryProvider>
              {children}
              <Toaster
                position="bottom-right"
                toastOptions={{
                  duration: 4000,
                  classNames: {
                    toast: 'bg-background text-foreground border-border',
                  },
                }}
              />
            </QueryProvider>
          </SupabaseProvider>
        </ThemeProvider>
      </body>
    </html>
  )
}
