// ============================================================================
// ExamForge AI — Route Constants
// ============================================================================
// Centralized route definitions, metadata, and navigation items.
// All route paths are defined as constants to avoid magic strings.
// Navigation items are grouped by section and include role-based visibility.
// ============================================================================

import type { UserRole } from '@/lib/types'
import {
  LayoutDashboard,
  FileText,
  HelpCircle,
  Users,
  GraduationCap,
  BookOpen,
  BarChart3,
  Settings,
  CreditCard,
  Store,
  Brain,
  CalendarDays,
  FolderOpen,
  Shield,
  School,
  UserCog,
  Lock,
  Activity,
  Bell,
  Globe,
  Database,
  Cpu,
  Wallet,
  Ticket,
  FileSpreadsheet,
  ClipboardList,
  MessageSquare,
  Sparkles,
  Target,
  BookMarked,
  Lightbulb,
  PenTool,
  Presentation,
  type LucideIcon,
} from 'lucide-react'

// ──────────────────────────────────────────────────────────────
// Route Path Constants
// ──────────────────────────────────────────────────────────────

export const ROUTES = {
  // Public routes
  LOGIN: '/login',
  REGISTER: '/register',
  FORGOT_PASSWORD: '/forgot-password',
  RESET_PASSWORD: '/reset-password',
  VERIFY_EMAIL: '/verify-email',
  AUTH_CALLBACK: '/api/auth/callback',

  // Authenticated routes
  DASHBOARD: '/dashboard',
  ONBOARDING: '/onboarding',
  PROFILE: '/profile',
  SETTINGS: '/settings',
  NOTIFICATIONS: '/notifications',

  // Exam routes
  EXAMS: '/exams',
  EXAM_CREATE: '/exams/create',
  EXAM_DETAIL: '/exams/[id]',
  EXAM_TAKE: '/exams/[id]/take',
  EXAM_RESULTS: '/exams/[id]/results',
  EXAM_TEMPLATES: '/exams/templates',

  // Question bank
  QUESTIONS: '/questions',
  QUESTIONS_CREATE: '/questions/create',

  // Student portal
  STUDENT_DASHBOARD: '/student',
  STUDENT_PRACTICE: '/student/practice',
  STUDENT_FLASHCARDS: '/student/flashcards',
  STUDENT_AI_TUTOR: '/student/ai-tutor',
  STUDENT_RESOURCES: '/student/resources',
  STUDENT_STUDY_PLANNER: '/student/study-planner',
  STUDENT_PROGRESS: '/student/progress',
  STUDENT_ASSIGNMENTS: '/student/assignments',
  STUDENT_GOALS: '/student/goals',

  // Teacher workspace
  TEACHER_DASHBOARD: '/teacher',
  TEACHER_LESSON_PLANS: '/teacher/lesson-plans',
  TEACHER_WORKSHEETS: '/teacher/worksheets',
  TEACHER_RUBRICS: '/teacher/rubrics',
  TEACHER_ASSIGNMENTS: '/teacher/assignments',
  TEACHER_PRESENTATIONS: '/teacher/presentations',
  TEACHER_ORAL_QUESTIONS: '/teacher/oral-questions',
  TEACHER_SCHEMES: '/teacher/schemes-of-work',
  TEACHER_RESOURCES: '/teacher/resources',
  TEACHER_CALENDAR: '/teacher/calendar',
  TEACHER_COMMUNICATIONS: '/teacher/communications',
  TEACHER_CONTENT_ASSISTANT: '/teacher/content-assistant',
  TEACHER_REPORT_COMMENTS: '/teacher/report-comments',
  TEACHER_PRACTICAL: '/teacher/practical-assessments',

  // School admin
  SCHOOL_DASHBOARD: '/school',
  SCHOOL_USERS: '/school/users',
  SCHOOL_CLASSES: '/school/classes',
  SCHOOL_SUBJECTS: '/school/subjects',
  SCHOOL_SETTINGS: '/school/settings',
  SCHOOL_BILLING: '/school/billing',

  // Super admin
  ADMIN_DASHBOARD: '/admin',
  ADMIN_USERS: '/admin/users',
  ADMIN_SCHOOLS: '/admin/schools',
  ADMIN_ANALYTICS: '/admin/analytics',
  ADMIN_BILLING: '/admin/billing',
  ADMIN_AI_MANAGEMENT: '/admin/ai',
  ADMIN_MARKETPLACE: '/admin/marketplace',
  ADMIN_SETTINGS: '/admin/settings',
  ADMIN_SECURITY: '/admin/security',
  ADMIN_SUPPORT: '/admin/support',
  ADMIN_INFRASTRUCTURE: '/admin/infrastructure',

  // Billing
  BILLING: '/billing',
  BILLING_PLANS: '/billing/plans',
  BILLING_HISTORY: '/billing/history',
  BILLING_CREDITS: '/billing/credits',

  // Marketplace
  MARKETPLACE: '/marketplace',

  // Analytics
  ANALYTICS: '/analytics',

  // Reports
  REPORTS: '/reports',

  // Search
  SEARCH: '/search',

  // CBT
  CBT: '/cbt',

  // Results
  RESULTS: '/results',

  // Question Bank
  QUESTION_BANK: '/question-bank',
} as const

export type RoutePath = (typeof ROUTES)[keyof typeof ROUTES]

// ──────────────────────────────────────────────────────────────
// Route Metadata
// ──────────────────────────────────────────────────────────────

export interface RouteMeta {
  title: string
  description: string
  icon: LucideIcon
  requiredRoles?: UserRole[]
  isPublic?: boolean
  badge?: string
}

export const ROUTE_META: Partial<Record<RoutePath, RouteMeta>> = {
  [ROUTES.LOGIN]: {
    title: 'Sign In',
    description: 'Sign in to your ExamForge AI account',
    icon: Lock,
    isPublic: true,
  },
  [ROUTES.REGISTER]: {
    title: 'Create Account',
    description: 'Create a new ExamForge AI account',
    icon: UserCog,
    isPublic: true,
  },
  [ROUTES.FORGOT_PASSWORD]: {
    title: 'Forgot Password',
    description: 'Reset your password',
    icon: Lock,
    isPublic: true,
  },
  [ROUTES.DASHBOARD]: {
    title: 'Dashboard',
    description: 'Your personal dashboard overview',
    icon: LayoutDashboard,
  },
  [ROUTES.EXAMS]: {
    title: 'Exams',
    description: 'Manage and take exams',
    icon: FileText,
  },
  [ROUTES.QUESTIONS]: {
    title: 'Question Bank',
    description: 'Browse and create questions',
    icon: HelpCircle,
  },
  [ROUTES.PROFILE]: {
    title: 'Profile',
    description: 'Manage your profile',
    icon: Users,
  },
  [ROUTES.SETTINGS]: {
    title: 'Settings',
    description: 'Application settings',
    icon: Settings,
  },
  [ROUTES.STUDENT_DASHBOARD]: {
    title: 'Student Portal',
    description: 'Your learning dashboard',
    icon: GraduationCap,
    requiredRoles: ['student'],
  },
  [ROUTES.STUDENT_PRACTICE]: {
    title: 'Practice Mode',
    description: 'Practice with AI-generated questions',
    icon: Target,
    requiredRoles: ['student'],
  },
  [ROUTES.STUDENT_FLASHCARDS]: {
    title: 'Flashcards',
    description: 'Study with flashcards',
    icon: BookMarked,
    requiredRoles: ['student'],
  },
  [ROUTES.STUDENT_AI_TUTOR]: {
    title: 'AI Tutor',
    description: 'Get help from your AI tutor',
    icon: Brain,
    requiredRoles: ['student'],
  },
  [ROUTES.STUDENT_RESOURCES]: {
    title: 'Resources',
    description: 'Learning resources library',
    icon: FolderOpen,
    requiredRoles: ['student'],
  },
  [ROUTES.STUDENT_STUDY_PLANNER]: {
    title: 'Study Planner',
    description: 'Plan your study schedule',
    icon: CalendarDays,
    requiredRoles: ['student'],
  },
  [ROUTES.STUDENT_PROGRESS]: {
    title: 'Progress',
    description: 'Track your learning progress',
    icon: BarChart3,
    requiredRoles: ['student'],
  },
  [ROUTES.STUDENT_ASSIGNMENTS]: {
    title: 'Assignments',
    description: 'View and submit assignments',
    icon: ClipboardList,
    requiredRoles: ['student'],
  },
  [ROUTES.STUDENT_GOALS]: {
    title: 'Goals',
    description: 'Set and track learning goals',
    icon: Target,
    requiredRoles: ['student'],
  },
  [ROUTES.TEACHER_DASHBOARD]: {
    title: 'Teacher Workspace',
    description: 'Your teaching workspace',
    icon: BookOpen,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.TEACHER_LESSON_PLANS]: {
    title: 'Lesson Plans',
    description: 'Create and manage lesson plans',
    icon: FileSpreadsheet,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.TEACHER_WORKSHEETS]: {
    title: 'Worksheets',
    description: 'Generate and manage worksheets',
    icon: FileText,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.TEACHER_RUBRICS]: {
    title: 'Rubrics',
    description: 'Create and manage rubrics',
    icon: ClipboardList,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.TEACHER_ASSIGNMENTS]: {
    title: 'Assignments',
    description: 'Create and manage assignments',
    icon: PenTool,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.TEACHER_PRESENTATIONS]: {
    title: 'Presentations',
    description: 'Generate presentations',
    icon: Presentation,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.TEACHER_CONTENT_ASSISTANT]: {
    title: 'Content Assistant',
    description: 'AI-powered content assistance',
    icon: Sparkles,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.TEACHER_RESOURCES]: {
    title: 'Resources',
    description: 'Teaching resources library',
    icon: FolderOpen,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.TEACHER_CALENDAR]: {
    title: 'Calendar',
    description: 'Schedule and calendar',
    icon: CalendarDays,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.TEACHER_REPORT_COMMENTS]: {
    title: 'Report Comments',
    description: 'Generate report comments',
    icon: MessageSquare,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.SCHOOL_DASHBOARD]: {
    title: 'School Admin',
    description: 'School administration dashboard',
    icon: School,
    requiredRoles: ['school_admin', 'super_admin'],
  },
  [ROUTES.SCHOOL_USERS]: {
    title: 'Users',
    description: 'Manage school users',
    icon: Users,
    requiredRoles: ['school_admin', 'super_admin'],
  },
  [ROUTES.ADMIN_DASHBOARD]: {
    title: 'Super Admin',
    description: 'Platform administration',
    icon: Shield,
    requiredRoles: ['super_admin'],
  },
  [ROUTES.ADMIN_USERS]: {
    title: 'User Management',
    description: 'Manage platform users',
    icon: UserCog,
    requiredRoles: ['super_admin'],
  },
  [ROUTES.ADMIN_SCHOOLS]: {
    title: 'School Management',
    description: 'Manage schools',
    icon: School,
    requiredRoles: ['super_admin'],
  },
  [ROUTES.ADMIN_ANALYTICS]: {
    title: 'Platform Analytics',
    description: 'Platform-wide analytics',
    icon: BarChart3,
    requiredRoles: ['super_admin'],
  },
  [ROUTES.ADMIN_BILLING]: {
    title: 'Billing Management',
    description: 'Manage billing and subscriptions',
    icon: Wallet,
    requiredRoles: ['super_admin'],
  },
  [ROUTES.ADMIN_AI_MANAGEMENT]: {
    title: 'AI Management',
    description: 'Manage AI models and usage',
    icon: Cpu,
    requiredRoles: ['super_admin'],
  },
  [ROUTES.ADMIN_MARKETPLACE]: {
    title: 'Marketplace',
    description: 'Manage marketplace content',
    icon: Store,
    requiredRoles: ['super_admin'],
  },
  [ROUTES.ADMIN_SECURITY]: {
    title: 'Security Center',
    description: 'Security settings and monitoring',
    icon: Lock,
    requiredRoles: ['super_admin'],
  },
  [ROUTES.ADMIN_SUPPORT]: {
    title: 'Support Center',
    description: 'Manage support tickets',
    icon: Bell,
    requiredRoles: ['super_admin'],
  },
  [ROUTES.ADMIN_INFRASTRUCTURE]: {
    title: 'Infrastructure',
    description: 'Infrastructure monitoring',
    icon: Database,
    requiredRoles: ['super_admin'],
  },
  [ROUTES.BILLING]: {
    title: 'Billing',
    description: 'Manage your subscription and billing',
    icon: CreditCard,
  },
  [ROUTES.BILLING_PLANS]: {
    title: 'Subscription Plans',
    description: 'View and change plans',
    icon: Ticket,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
  [ROUTES.MARKETPLACE]: {
    title: 'Marketplace',
    description: 'Browse and purchase educational content',
    icon: Store,
  },
  [ROUTES.ANALYTICS]: {
    title: 'Analytics',
    description: 'View detailed analytics',
    icon: BarChart3,
    requiredRoles: ['teacher', 'school_admin', 'super_admin'],
  },
}

// ──────────────────────────────────────────────────────────────
// Navigation Item Interface
// ──────────────────────────────────────────────────────────────

export interface NavItem {
  title: string
  href: string
  icon: LucideIcon
  requiredRoles?: UserRole[]
  badge?: string
  badgeVariant?: 'default' | 'secondary' | 'destructive' | 'outline'
  children?: NavItem[]
}

export interface NavSection {
  label: string
  items: NavItem[]
}

// ──────────────────────────────────────────────────────────────
// Navigation Items by Section
// ──────────────────────────────────────────────────────────────

export const MAIN_NAV: NavSection[] = [
  {
    label: 'Overview',
    items: [
      {
        title: 'Dashboard',
        href: ROUTES.DASHBOARD,
        icon: LayoutDashboard,
      },
    ],
  },
  {
    label: 'Exams',
    items: [
      {
        title: 'All Exams',
        href: ROUTES.CBT,
        icon: FileText,
      },
      {
        title: 'Results',
        href: ROUTES.RESULTS,
        icon: ClipboardList,
      },
      {
        title: 'Question Bank',
        href: ROUTES.QUESTION_BANK,
        icon: HelpCircle,
      },
    ],
  },
  {
    label: 'Student Portal',
    items: [
      {
        title: 'My Dashboard',
        href: ROUTES.STUDENT_DASHBOARD,
        icon: GraduationCap,
        requiredRoles: ['student'],
      },
      {
        title: 'Practice Mode',
        href: ROUTES.STUDENT_PRACTICE,
        icon: Target,
        requiredRoles: ['student'],
      },
      {
        title: 'Flashcards',
        href: ROUTES.STUDENT_FLASHCARDS,
        icon: BookMarked,
        requiredRoles: ['student'],
      },
      {
        title: 'AI Tutor',
        href: ROUTES.STUDENT_AI_TUTOR,
        icon: Brain,
        requiredRoles: ['student'],
      },
      {
        title: 'Study Planner',
        href: ROUTES.STUDENT_STUDY_PLANNER,
        icon: CalendarDays,
        requiredRoles: ['student'],
      },
      {
        title: 'Resources',
        href: ROUTES.STUDENT_RESOURCES,
        icon: FolderOpen,
        requiredRoles: ['student'],
      },
      {
        title: 'Progress',
        href: ROUTES.STUDENT_PROGRESS,
        icon: BarChart3,
        requiredRoles: ['student'],
      },
      {
        title: 'Assignments',
        href: ROUTES.STUDENT_ASSIGNMENTS,
        icon: ClipboardList,
        requiredRoles: ['student'],
      },
      {
        title: 'Goals',
        href: ROUTES.STUDENT_GOALS,
        icon: Lightbulb,
        requiredRoles: ['student'],
      },
    ],
  },
  {
    label: 'Teacher Workspace',
    items: [
      {
        title: 'Workspace',
        href: ROUTES.TEACHER_DASHBOARD,
        icon: BookOpen,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Lesson Plans',
        href: ROUTES.TEACHER_LESSON_PLANS,
        icon: FileSpreadsheet,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Worksheets',
        href: ROUTES.TEACHER_WORKSHEETS,
        icon: FileText,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Assignments',
        href: ROUTES.TEACHER_ASSIGNMENTS,
        icon: PenTool,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Presentations',
        href: ROUTES.TEACHER_PRESENTATIONS,
        icon: Presentation,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Content Assistant',
        href: ROUTES.TEACHER_CONTENT_ASSISTANT,
        icon: Sparkles,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
        badge: 'AI',
        badgeVariant: 'secondary',
      },
      {
        title: 'Rubrics',
        href: ROUTES.TEACHER_RUBRICS,
        icon: ClipboardList,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Resources',
        href: ROUTES.TEACHER_RESOURCES,
        icon: FolderOpen,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Calendar',
        href: ROUTES.TEACHER_CALENDAR,
        icon: CalendarDays,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Report Comments',
        href: ROUTES.TEACHER_REPORT_COMMENTS,
        icon: MessageSquare,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
    ],
  },
  {
    label: 'School Admin',
    items: [
      {
        title: 'School Dashboard',
        href: ROUTES.SCHOOL_DASHBOARD,
        icon: School,
        requiredRoles: ['school_admin', 'super_admin'],
      },
      {
        title: 'Users',
        href: ROUTES.SCHOOL_USERS,
        icon: Users,
        requiredRoles: ['school_admin', 'super_admin'],
      },
    ],
  },
  {
    label: 'Super Admin',
    items: [
      {
        title: 'Admin Dashboard',
        href: ROUTES.ADMIN_DASHBOARD,
        icon: Shield,
        requiredRoles: ['super_admin'],
      },
      {
        title: 'User Management',
        href: ROUTES.ADMIN_USERS,
        icon: UserCog,
        requiredRoles: ['super_admin'],
      },
      {
        title: 'School Management',
        href: ROUTES.ADMIN_SCHOOLS,
        icon: School,
        requiredRoles: ['super_admin'],
      },
      {
        title: 'Analytics',
        href: ROUTES.ADMIN_ANALYTICS,
        icon: Activity,
        requiredRoles: ['super_admin'],
      },
      {
        title: 'Billing',
        href: ROUTES.ADMIN_BILLING,
        icon: Wallet,
        requiredRoles: ['super_admin'],
      },
      {
        title: 'AI Management',
        href: ROUTES.ADMIN_AI_MANAGEMENT,
        icon: Cpu,
        requiredRoles: ['super_admin'],
      },
      {
        title: 'Marketplace',
        href: ROUTES.ADMIN_MARKETPLACE,
        icon: Globe,
        requiredRoles: ['super_admin'],
      },
      {
        title: 'Security',
        href: ROUTES.ADMIN_SECURITY,
        icon: Lock,
        requiredRoles: ['super_admin'],
      },
      {
        title: 'Support',
        href: ROUTES.ADMIN_SUPPORT,
        icon: Bell,
        requiredRoles: ['super_admin'],
      },
      {
        title: 'Infrastructure',
        href: ROUTES.ADMIN_INFRASTRUCTURE,
        icon: Database,
        requiredRoles: ['super_admin'],
      },
    ],
  },
  {
    label: 'Account',
    items: [
      {
        title: 'Billing',
        href: ROUTES.BILLING,
        icon: CreditCard,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Marketplace',
        href: ROUTES.MARKETPLACE,
        icon: Store,
      },
      {
        title: 'Analytics',
        href: ROUTES.ANALYTICS,
        icon: BarChart3,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Reports',
        href: ROUTES.REPORTS,
        icon: FileSpreadsheet,
        requiredRoles: ['teacher', 'school_admin', 'super_admin'],
      },
      {
        title: 'Search',
        href: ROUTES.SEARCH,
        icon: Globe,
      },
      {
        title: 'Settings',
        href: ROUTES.SETTINGS,
        icon: Settings,
      },
    ],
  },
]

// ──────────────────────────────────────────────────────────────
// Public Route Paths
// ──────────────────────────────────────────────────────────────

export const PUBLIC_ROUTES: string[] = [
  ROUTES.LOGIN,
  ROUTES.REGISTER,
  ROUTES.FORGOT_PASSWORD,
  ROUTES.RESET_PASSWORD,
  ROUTES.VERIFY_EMAIL,
  ROUTES.AUTH_CALLBACK,
]

// ──────────────────────────────────────────────────────────────
// Role-Based Route Access Map
// ──────────────────────────────────────────────────────────────

export const ROLE_ROUTE_ACCESS: Record<UserRole, string[]> = {
  student: [
    ROUTES.DASHBOARD,
    ROUTES.EXAMS,
    ROUTES.QUESTIONS,
    ROUTES.STUDENT_DASHBOARD,
    ROUTES.STUDENT_PRACTICE,
    ROUTES.STUDENT_FLASHCARDS,
    ROUTES.STUDENT_AI_TUTOR,
    ROUTES.STUDENT_RESOURCES,
    ROUTES.STUDENT_STUDY_PLANNER,
    ROUTES.STUDENT_PROGRESS,
    ROUTES.STUDENT_ASSIGNMENTS,
    ROUTES.STUDENT_GOALS,
    ROUTES.MARKETPLACE,
    ROUTES.BILLING,
    ROUTES.PROFILE,
    ROUTES.SETTINGS,
    ROUTES.NOTIFICATIONS,
  ],
  teacher: [
    ROUTES.DASHBOARD,
    ROUTES.EXAMS,
    ROUTES.QUESTIONS,
    ROUTES.TEACHER_DASHBOARD,
    ROUTES.TEACHER_LESSON_PLANS,
    ROUTES.TEACHER_WORKSHEETS,
    ROUTES.TEACHER_RUBRICS,
    ROUTES.TEACHER_ASSIGNMENTS,
    ROUTES.TEACHER_PRESENTATIONS,
    ROUTES.TEACHER_ORAL_QUESTIONS,
    ROUTES.TEACHER_SCHEMES,
    ROUTES.TEACHER_RESOURCES,
    ROUTES.TEACHER_CALENDAR,
    ROUTES.TEACHER_COMMUNICATIONS,
    ROUTES.TEACHER_CONTENT_ASSISTANT,
    ROUTES.TEACHER_REPORT_COMMENTS,
    ROUTES.TEACHER_PRACTICAL,
    ROUTES.MARKETPLACE,
    ROUTES.BILLING,
    ROUTES.BILLING_PLANS,
    ROUTES.BILLING_CREDITS,
    ROUTES.ANALYTICS,
    ROUTES.PROFILE,
    ROUTES.SETTINGS,
    ROUTES.NOTIFICATIONS,
  ],
  school_admin: [
    ROUTES.DASHBOARD,
    ROUTES.EXAMS,
    ROUTES.QUESTIONS,
    ROUTES.TEACHER_DASHBOARD,
    ROUTES.TEACHER_LESSON_PLANS,
    ROUTES.TEACHER_WORKSHEETS,
    ROUTES.TEACHER_RUBRICS,
    ROUTES.TEACHER_ASSIGNMENTS,
    ROUTES.TEACHER_PRESENTATIONS,
    ROUTES.TEACHER_CONTENT_ASSISTANT,
    ROUTES.TEACHER_RESOURCES,
    ROUTES.TEACHER_CALENDAR,
    ROUTES.TEACHER_REPORT_COMMENTS,
    ROUTES.SCHOOL_DASHBOARD,
    ROUTES.SCHOOL_USERS,
    ROUTES.SCHOOL_CLASSES,
    ROUTES.SCHOOL_SUBJECTS,
    ROUTES.SCHOOL_SETTINGS,
    ROUTES.SCHOOL_BILLING,
    ROUTES.MARKETPLACE,
    ROUTES.BILLING,
    ROUTES.BILLING_PLANS,
    ROUTES.ANALYTICS,
    ROUTES.PROFILE,
    ROUTES.SETTINGS,
    ROUTES.NOTIFICATIONS,
  ],
  super_admin: [
    ROUTES.DASHBOARD,
    ROUTES.EXAMS,
    ROUTES.QUESTIONS,
    ROUTES.ADMIN_DASHBOARD,
    ROUTES.ADMIN_USERS,
    ROUTES.ADMIN_SCHOOLS,
    ROUTES.ADMIN_ANALYTICS,
    ROUTES.ADMIN_BILLING,
    ROUTES.ADMIN_AI_MANAGEMENT,
    ROUTES.ADMIN_MARKETPLACE,
    ROUTES.ADMIN_SETTINGS,
    ROUTES.ADMIN_SECURITY,
    ROUTES.ADMIN_SUPPORT,
    ROUTES.ADMIN_INFRASTRUCTURE,
    ROUTES.SCHOOL_DASHBOARD,
    ROUTES.SCHOOL_USERS,
    ROUTES.TEACHER_DASHBOARD,
    ROUTES.TEACHER_LESSON_PLANS,
    ROUTES.TEACHER_WORKSHEETS,
    ROUTES.TEACHER_RUBRICS,
    ROUTES.TEACHER_ASSIGNMENTS,
    ROUTES.TEACHER_PRESENTATIONS,
    ROUTES.TEACHER_CONTENT_ASSISTANT,
    ROUTES.TEACHER_RESOURCES,
    ROUTES.MARKETPLACE,
    ROUTES.BILLING,
    ROUTES.ANALYTICS,
    ROUTES.PROFILE,
    ROUTES.SETTINGS,
    ROUTES.NOTIFICATIONS,
  ],
}

// ──────────────────────────────────────────────────────────────
// Route Segment Labels (for breadcrumbs)
// ──────────────────────────────────────────────────────────────

export const ROUTE_SEGMENT_LABELS: Record<string, string> = {
  dashboard: 'Dashboard',
  login: 'Sign In',
  register: 'Create Account',
  'forgot-password': 'Forgot Password',
  'reset-password': 'Reset Password',
  'verify-email': 'Verify Email',
  onboarding: 'Onboarding',
  profile: 'Profile',
  settings: 'Settings',
  notifications: 'Notifications',
  exams: 'Exams',
  create: 'Create',
  take: 'Take',
  results: 'Results',
  templates: 'Templates',
  questions: 'Question Bank',
  student: 'Student Portal',
  practice: 'Practice',
  flashcards: 'Flashcards',
  'ai-tutor': 'AI Tutor',
  resources: 'Resources',
  'study-planner': 'Study Planner',
  progress: 'Progress',
  assignments: 'Assignments',
  goals: 'Goals',
  teacher: 'Teacher Workspace',
  'lesson-plans': 'Lesson Plans',
  worksheets: 'Worksheets',
  rubrics: 'Rubrics',
  presentations: 'Presentations',
  'oral-questions': 'Oral Questions',
  'schemes-of-work': 'Schemes of Work',
  calendar: 'Calendar',
  communications: 'Communications',
  'content-assistant': 'Content Assistant',
  'report-comments': 'Report Comments',
  'practical-assessments': 'Practical Assessments',
  school: 'School Admin',
  users: 'Users',
  classes: 'Classes',
  subjects: 'Subjects',
  billing: 'Billing',
  plans: 'Plans',
  history: 'History',
  credits: 'Credits',
  admin: 'Admin',
  analytics: 'Analytics',
  ai: 'AI Management',
  marketplace: 'Marketplace',
  security: 'Security',
  support: 'Support',
  infrastructure: 'Infrastructure',
}
