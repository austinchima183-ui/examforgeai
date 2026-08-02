'use client'

import { useState } from 'react'
import { Sidebar } from '@/components/layout/sidebar'
import { Header } from '@/components/layout/header'
import { MobileNav } from '@/components/layout/mobile-nav'
import { useIsMobile } from '@/hooks/use-mobile'
import { RealtimeProvider } from '@/lib/hooks/use-realtime-provider'

// ============================================================================
// ExamForge AI — Authenticated Layout (AppShell)
// ============================================================================
// Layout for all authenticated routes. Provides the sidebar navigation,
// header with breadcrumbs, and mobile-responsive navigation.
// ============================================================================

export default function AppLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  const isMobile = useIsMobile()
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false)
  const [mobileNavOpen, setMobileNavOpen] = useState(false)

  return (
    <RealtimeProvider>
      <div className="min-h-screen flex bg-background">
      {/* Desktop Sidebar */}
      {!isMobile && (
        <Sidebar
          collapsed={sidebarCollapsed}
          onToggleCollapse={() => setSidebarCollapsed(!sidebarCollapsed)}
        />
      )}

      {/* Mobile Navigation (Sheet) */}
      {isMobile && (
        <MobileNav open={mobileNavOpen} onOpenChange={setMobileNavOpen} />
      )}

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        <Header
          sidebarCollapsed={sidebarCollapsed}
          onToggleSidebar={() => {
            if (isMobile) {
              setMobileNavOpen(!mobileNavOpen)
            } else {
              setSidebarCollapsed(!sidebarCollapsed)
            }
          }}
        />

        <main className="flex-1 overflow-auto">
          <div className="container max-w-7xl mx-auto p-4 sm:p-6 lg:p-8">
            {children}
          </div>
        </main>
      </div>
      </div>
    </RealtimeProvider>
  )
}
