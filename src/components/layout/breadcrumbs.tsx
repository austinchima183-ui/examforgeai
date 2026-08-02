'use client'

import Link from 'next/link'
import {
  Breadcrumb,
  BreadcrumbList,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from '@/components/ui/breadcrumb'
import { ROUTE_SEGMENT_LABELS } from '@/lib/constants/routes'

// ============================================================================
// ExamForge AI — Breadcrumbs Component
// ============================================================================
// Generates breadcrumb navigation from the current pathname.
// Maps route segments to readable labels using ROUTE_SEGMENT_LABELS.
// Uses the shadcn/ui Breadcrumb component.
// ============================================================================

interface BreadcrumbsProps {
  pathname: string
}

// ──────────────────────────────────────────────────────────────
// Helper: Build breadcrumb items from pathname
// ──────────────────────────────────────────────────────────────

interface BreadcrumbEntry {
  label: string
  href: string
  isLast: boolean
}

function buildBreadcrumbs(pathname: string): BreadcrumbEntry[] {
  // Remove leading/trailing slashes and split
  const segments = pathname.replace(/^\/|\/$/g, '').split('/').filter(Boolean)

  if (segments.length === 0) {
    return [{ label: 'Home', href: '/dashboard', isLast: true }]
  }

  const breadcrumbs: BreadcrumbEntry[] = []

  // Always add Dashboard as the first crumb
  breadcrumbs.push({
    label: 'Dashboard',
    href: '/dashboard',
    isLast: segments.length === 1 && segments[0] === 'dashboard',
  })

  // Build crumbs from path segments
  let currentPath = ''
  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i]
    currentPath += `/${segment}`

    // Skip if this is the dashboard segment (already added above)
    if (segment === 'dashboard' && i === 0) continue

    // Skip dynamic segments (e.g., [id]) — they're not meaningful for labels
    const isDynamic = /^\[.*\]$/.test(segment) || /^[a-f0-9-]{8,}$/i.test(segment)

    const label = isDynamic
      ? 'Details'
      : ROUTE_SEGMENT_LABELS[segment] ?? segment.replace(/-/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())

    const isLast = i === segments.length - 1

    breadcrumbs.push({
      label,
      href: currentPath,
      isLast,
    })
  }

  // If the first crumb is the only one and it's the last, adjust
  if (breadcrumbs.length === 1 && breadcrumbs[0].isLast) {
    return breadcrumbs
  }

  // If first crumb is dashboard and it's not the last, mark it as not last
  if (breadcrumbs.length > 1) {
    breadcrumbs[0].isLast = false
  }

  return breadcrumbs
}

// ──────────────────────────────────────────────────────────────
// Breadcrumbs Component
// ──────────────────────────────────────────────────────────────

export function Breadcrumbs({ pathname }: BreadcrumbsProps) {
  const items = buildBreadcrumbs(pathname)

  return (
    <Breadcrumb>
      <BreadcrumbList>
        {items.map((item, index) => (
          <BreadcrumbItem key={item.href}>
            {item.isLast ? (
              <BreadcrumbPage>{item.label}</BreadcrumbPage>
            ) : (
              <BreadcrumbLink asChild>
                <Link href={item.href}>{item.label}</Link>
              </BreadcrumbLink>
            )}
            {index < items.length - 1 && <BreadcrumbSeparator />}
          </BreadcrumbItem>
        ))}
      </BreadcrumbList>
    </Breadcrumb>
  )
}
