'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useMemo } from 'react'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/lib/stores/auth-store'
import { MAIN_NAV, type NavSection, type NavItem } from '@/lib/constants/routes'
import { Button } from '@/components/ui/button'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Separator } from '@/components/ui/separator'
import { Badge } from '@/components/ui/badge'
import { Tooltip, TooltipTrigger, TooltipContent } from '@/components/ui/tooltip'
import {
  ChevronLeft,
  ChevronRight,
  type LucideIcon,
} from 'lucide-react'

// ============================================================================
// ExamForge AI — Sidebar Component
// ============================================================================
// Desktop sidebar navigation with role-filtered items, collapsible state,
// and active item highlighting. Uses shadcn/ui components and Lucide icons.
// ============================================================================

interface SidebarProps {
  collapsed: boolean
  onToggleCollapse: () => void
}

// ──────────────────────────────────────────────────────────────
// Nav Item Component
// ──────────────────────────────────────────────────────────────

function SidebarNavItem({
  item,
  isActive,
  collapsed,
}: {
  item: NavItem
  isActive: boolean
  collapsed: boolean
}) {
  const Icon: LucideIcon = item.icon

  const linkContent = (
    <Link
      href={item.href}
      className={cn(
        'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-all duration-150',
        'hover:bg-accent hover:text-accent-foreground',
        isActive
          ? 'bg-accent text-accent-foreground'
          : 'text-muted-foreground',
        collapsed && 'justify-center px-2'
      )}
    >
      <Icon className="h-4 w-4 shrink-0" />
      {!collapsed && (
        <span className="truncate">{item.title}</span>
      )}
      {!collapsed && item.badge && (
        <Badge
          variant={item.badgeVariant ?? 'default'}
          className="ml-auto text-[10px] px-1.5 py-0 h-5"
        >
          {item.badge}
        </Badge>
      )}
    </Link>
  )

  // When collapsed, wrap in tooltip to show the label
  if (collapsed) {
    return (
      <Tooltip delayDuration={0}>
        <TooltipTrigger asChild>
          {linkContent}
        </TooltipTrigger>
        <TooltipContent side="right" sideOffset={8}>
          {item.title}
          {item.badge && ` (${item.badge})`}
        </TooltipContent>
      </Tooltip>
    )
  }

  return linkContent
}

// ──────────────────────────────────────────────────────────────
// Sidebar Component
// ──────────────────────────────────────────────────────────────

export function Sidebar({ collapsed, onToggleCollapse }: SidebarProps) {
  const pathname = usePathname()
  const { role } = useAuthStore()

  // Filter navigation sections based on user role
  const filteredNav = useMemo(() => {
    if (!role) return MAIN_NAV

    return MAIN_NAV.map((section: NavSection) => ({
      ...section,
      items: section.items.filter((item: NavItem) => {
        if (!item.requiredRoles || item.requiredRoles.length === 0) return true
        return item.requiredRoles.includes(role)
      }),
    })).filter((section: NavSection) => section.items.length > 0)
  }, [role])

  // Check if a nav item is active
  const isItemActive = (href: string): boolean => {
    if (href === '/dashboard') {
      return pathname === '/dashboard'
    }
    return pathname === href || pathname.startsWith(href + '/')
  }

  return (
    <aside
      className={cn(
        'relative flex flex-col border-r bg-sidebar text-sidebar-foreground transition-all duration-300 ease-in-out',
        collapsed ? 'w-16' : 'w-64'
      )}
    >
      {/* Logo / Brand */}
      <div className={cn(
        'flex items-center h-16 px-4 border-b shrink-0',
        collapsed ? 'justify-center' : 'gap-2'
      )}>
        <div className="h-8 w-8 rounded-lg bg-primary flex items-center justify-center shrink-0">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            className="h-5 w-5 text-primary-foreground"
          >
            <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" />
            <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" />
          </svg>
        </div>
        {!collapsed && (
          <span className="text-lg font-bold tracking-tight">ExamForge AI</span>
        )}
      </div>

      {/* Navigation */}
      <ScrollArea className="flex-1 py-2">
        <nav className="flex flex-col gap-1 px-2">
          {filteredNav.map((section: NavSection, sectionIndex: number) => (
            <div key={section.label}>
              {/* Section label */}
              {!collapsed && (
                <div className="px-3 py-2">
                  <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                    {section.label}
                  </span>
                </div>
              )}

              {/* Section items */}
              {collapsed && sectionIndex > 0 && (
                <Separator className="my-2 mx-2" />
              )}

              {section.items.map((item: NavItem) => (
                <SidebarNavItem
                  key={item.href}
                  item={item}
                  isActive={isItemActive(item.href)}
                  collapsed={collapsed}
                />
              ))}
            </div>
          ))}
        </nav>
      </ScrollArea>

      {/* Collapse Toggle */}
      <div className="border-t p-2 shrink-0">
        <Button
          variant="ghost"
          size="sm"
          className={cn(
            'w-full justify-center',
            !collapsed && 'justify-start'
          )}
          onClick={onToggleCollapse}
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          {collapsed ? (
            <ChevronRight className="h-4 w-4" />
          ) : (
            <>
              <ChevronLeft className="h-4 w-4" />
              <span className="text-xs text-muted-foreground">Collapse</span>
            </>
          )}
        </Button>
      </div>
    </aside>
  )
}
