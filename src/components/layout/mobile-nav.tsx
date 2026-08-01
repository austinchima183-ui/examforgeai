'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useMemo } from 'react'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/lib/stores/auth-store'
import { MAIN_NAV, type NavSection, type NavItem } from '@/lib/constants/routes'
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from '@/components/ui/sheet'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Separator } from '@/components/ui/separator'
import { Badge } from '@/components/ui/badge'
import { type LucideIcon } from 'lucide-react'

// ============================================================================
// ExamForge AI — Mobile Navigation
// ============================================================================
// Sheet-based mobile navigation triggered by the header hamburger button.
// Uses the same navigation items as the sidebar, filtered by user role.
// ============================================================================

interface MobileNavProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

// ──────────────────────────────────────────────────────────────
// Mobile Nav Item
// ──────────────────────────────────────────────────────────────

function MobileNavItem({
  item,
  isActive,
  onClick,
}: {
  item: NavItem
  isActive: boolean
  onClick: () => void
}) {
  const Icon: LucideIcon = item.icon

  return (
    <Link
      href={item.href}
      onClick={onClick}
      className={cn(
        'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
        'hover:bg-accent hover:text-accent-foreground',
        isActive
          ? 'bg-accent text-accent-foreground'
          : 'text-muted-foreground'
      )}
    >
      <Icon className="h-4 w-4 shrink-0" />
      <span className="truncate">{item.title}</span>
      {item.badge && (
        <Badge
          variant={item.badgeVariant ?? 'default'}
          className="ml-auto text-[10px] px-1.5 py-0 h-5"
        >
          {item.badge}
        </Badge>
      )}
    </Link>
  )
}

// ──────────────────────────────────────────────────────────────
// Mobile Navigation Component
// ──────────────────────────────────────────────────────────────

export function MobileNav({ open, onOpenChange }: MobileNavProps) {
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

  // Close the sheet when a link is clicked
  const handleLinkClick = () => {
    onOpenChange(false)
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="left" className="w-72 p-0">
        <SheetHeader className="px-4 pt-4 pb-2 border-b">
          <SheetTitle className="flex items-center gap-2">
            <div className="h-8 w-8 rounded-lg bg-primary flex items-center justify-center">
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
            ExamForge AI
          </SheetTitle>
          <SheetDescription className="sr-only">
            Navigation menu for ExamForge AI
          </SheetDescription>
        </SheetHeader>

        <ScrollArea className="flex-1 h-[calc(100vh-5rem)]">
          <nav className="flex flex-col gap-1 p-2">
            {filteredNav.map((section: NavSection, sectionIndex: number) => (
              <div key={section.label}>
                {/* Section label */}
                <div className="px-3 py-2 mt-2 first:mt-0">
                  <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                    {section.label}
                  </span>
                </div>

                {/* Section items */}
                {section.items.map((item: NavItem) => (
                  <MobileNavItem
                    key={item.href}
                    item={item}
                    isActive={isItemActive(item.href)}
                    onClick={handleLinkClick}
                  />
                ))}

                {/* Separator between sections */}
                {sectionIndex < filteredNav.length - 1 && (
                  <Separator className="my-2" />
                )}
              </div>
            ))}
          </nav>
        </ScrollArea>
      </SheetContent>
    </Sheet>
  )
}
