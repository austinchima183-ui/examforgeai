# Task: ExamForge AI — Core Layout & Middleware Infrastructure

## Task ID: task-001
## Agent: Main Agent
## Status: Completed

## Summary

Created the complete ExamForge AI production codebase infrastructure including middleware, layouts, providers, navigation components, and route constants. All 12 requested files plus 2 supporting pages were created with full TypeScript, no placeholders, no TODOs.

## Files Created

### 1. `/src/lib/constants/routes.ts` — Route Constants
- All route paths as typed constants (`ROUTES`)
- Route metadata with title, description, icon, requiredRole (`ROUTE_META`)
- Navigation items grouped by section (`MAIN_NAV`)
- Public route paths list (`PUBLIC_ROUTES`)
- Role-based route access map (`ROLE_ROUTE_ACCESS`)
- Route segment labels for breadcrumbs (`ROUTE_SEGMENT_LABELS`)
- Full Lucide icon imports for all navigation items

### 2. `/src/lib/constants/index.ts` — Barrel Export
- Central export point for all constants

### 3. `/src/lib/hooks/use-supabase.tsx` — Supabase Context Provider
- Creates browser Supabase client via `createClient()` from `@/lib/supabase/client`
- Provides via React context (`SupabaseContext`)
- `useSupabase()` hook with error boundary if used outside provider
- `SupabaseProvider` component wraps children

### 4. `/src/lib/hooks/use-query-provider.tsx` — TanStack Query Provider
- Creates `QueryClient` with default options (staleTime: 60s, gcTime: 5min)
- SSR-safe singleton pattern (different client for server vs browser)
- `QueryProvider` component wraps children with `QueryClientProvider`

### 5. `/src/middleware.ts` — Root Middleware
- Uses `@supabase/ssr` `createClient` pattern from `@/lib/supabase/middleware`
- Guard chain: AuthGuard → OnboardingGuard → RoleBasedGuard
- Public routes: /login, /register, /forgot-password, /reset-password, /verify-email, /api/auth/callback
- No session on protected route → redirect to /login with redirect param
- Session on auth route → redirect to /dashboard
- Onboarding check via `app_metadata.onboarding_complete`
- Role-based: /admin needs super_admin, /school needs school_admin+, /teacher needs teacher+, /student needs student
- Role read from JWT `app_metadata.role`
- Config matcher excludes _next/static, _next/image, favicon, public files

### 6. `/src/app/layout.tsx` — Root Layout (REPLACED)
- Inter font from `next/font/google`
- `ThemeProvider` from `next-themes` (attribute="class", system theme)
- `SupabaseProvider` wrapping app
- `QueryProvider` wrapping app
- `Toaster` from `sonner` (bottom-right, themed)
- Full metadata: title "ExamForge AI", description, keywords, OpenGraph, Twitter
- Viewport config with theme color

### 7. `/src/app/(public)/layout.tsx` — Public Layout
- Centered card layout with gradient background
- Decorative blur elements for visual depth
- Logo with book icon
- "ExamForge AI" branding
- Footer with copyright
- No navigation chrome

### 8. `/src/app/(app)/layout.tsx` — Authenticated Layout (AppShell)
- Uses `Sidebar`, `Header`, `MobileNav` components
- Sidebar collapsible state managed via `useState`
- Mobile responsive: sidebar becomes Sheet on mobile
- Desktop: sidebar + header + main content area
- Container max-width 7xl with responsive padding

### 9. `/src/components/layout/sidebar.tsx` — Sidebar Component
- Client component with `'use client'` directive
- Navigation items grouped by section with labels
- Role-filtered items using `useAuthStore`
- Collapsible with animation (width transition)
- Active item highlight (bg-accent)
- Logo at top with book icon
- Tooltip on collapsed items for accessibility
- Uses shadcn/ui: Button, ScrollArea, Separator, Badge, Tooltip
- Lucide icons for all nav items
- Collapse toggle button at bottom

### 10. `/src/components/layout/header.tsx` — Header Component
- Client component with `'use client'` directive
- Breadcrumb navigation via `Breadcrumbs` component
- Search trigger button (placeholder for command palette)
- Theme toggle (sun/moon with animation)
- Notification bell with unread count badge
- User menu dropdown (avatar, name, role, profile, billing, settings, help, logout)
- Mobile menu button (hamburger)
- Uses shadcn/ui: Button, DropdownMenu, Avatar, Badge
- Logout handler using Supabase signOut + auth store clear

### 11. `/src/components/layout/mobile-nav.tsx` — Mobile Navigation
- Client component with `'use client'` directive
- Sheet component from shadcn/ui (side="left")
- Same navigation items as sidebar, role-filtered
- Triggered by header hamburger button
- Auto-closes on link click
- Logo in sheet header
- ScrollArea for long navigation

### 12. `/src/components/layout/breadcrumbs.tsx` — Breadcrumb Component
- Client component with `'use client'` directive
- Uses pathname to generate breadcrumb items
- Maps route segments to readable labels via `ROUTE_SEGMENT_LABELS`
- Dynamic segments (UUIDs, [id]) shown as "Details"
- Dashboard always first crumb
- Uses shadcn/ui Breadcrumb components
- Links on non-last items, plain text on last

## Supporting Files Created

### `/src/app/(public)/login/page.tsx` — Login Page
- Email/password form with Supabase auth
- Loading state, error handling
- Links to forgot-password and register

### `/src/app/(app)/dashboard/page.tsx` — Dashboard Page
- Role-appropriate welcome message
- Quick stats grid (Exams, Questions, Practice/Students, Performance)
- Feature cards (AI Generation, CBT Engine, Learning Portal)

### `/src/app/page.tsx` — Root Page (Updated)
- Redirects to /dashboard (middleware handles auth)

## Technical Notes

- All imports use `@/` path aliases
- TypeScript strict mode compliant
- All client components have `'use client'` directive
- No indigo/blue colors used in UI
- Responsive design with mobile-first approach
- Accessibility: ARIA labels, semantic HTML, keyboard navigation
- Uses existing Zustand stores (auth-store, notification-store, ui-store)
- Uses existing Supabase client infrastructure
- No lint errors in src/ files
- No TypeScript errors in src/ files
- Dev server running successfully on port 3000
