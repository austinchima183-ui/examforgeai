// ============================================================================
// ExamForge AI — Shared Type Definitions
// ============================================================================
// Central type definitions used across the application.
// UserRole is imported from here by stores, validators, and components.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// User Roles
// ──────────────────────────────────────────────────────────────

export type UserRole = 'student' | 'teacher' | 'school_admin' | 'super_admin';

// ──────────────────────────────────────────────────────────────
// User
// ──────────────────────────────────────────────────────────────

export interface User {
  id: string;
  email: string;
  fullName: string;
  role: UserRole;
  avatarUrl?: string | null;
  phone?: string | null;
  isEmailVerified: boolean;
  createdAt: string;
  updatedAt: string;
}

// ──────────────────────────────────────────────────────────────
// Question Types
// ──────────────────────────────────────────────────────────────

export type QuestionType =
  | 'multiple_choice'
  | 'multi_select'
  | 'true_false'
  | 'short_answer'
  | 'essay'
  | 'fill_in_blank'
  | 'matching'
  | 'ordering'
  | 'numerical';

export type DifficultyLevel = 'easy' | 'medium' | 'hard' | 'expert';

export interface QuestionOption {
  id: string;
  label: string;
  content: string;
  isCorrect?: boolean;
}

// ──────────────────────────────────────────────────────────────
// Exam Types
// ──────────────────────────────────────────────────────────────

export type ExamStatus = 'draft' | 'published' | 'active' | 'completed' | 'archived' | 'cancelled';

export interface ExamSettings {
  shuffleQuestions: boolean;
  showResults: boolean;
  allowReview: boolean;
  autoSubmit: boolean;
}

// ──────────────────────────────────────────────────────────────
// UI / Toast Types
// ──────────────────────────────────────────────────────────────

export type ToastVariant = 'default' | 'success' | 'error' | 'warning' | 'info';

export interface Toast {
  id: string;
  title: string;
  description?: string;
  variant?: ToastVariant;
  duration?: number;
  createdAt: number;
}

// ──────────────────────────────────────────────────────────────
// Notification Types
// ──────────────────────────────────────────────────────────────

export type NotificationPermissionStatus = 'default' | 'granted' | 'denied';

// ──────────────────────────────────────────────────────────────
// Sync Status for CBT Offline Support
// ──────────────────────────────────────────────────────────────

export type SyncStatus = 'idle' | 'syncing' | 'synced' | 'error' | 'offline';

// ──────────────────────────────────────────────────────────────
// Active Module Type
// ──────────────────────────────────────────────────────────────

export type ActiveModule =
  | 'dashboard'
  | 'exams'
  | 'questions'
  | 'students'
  | 'teachers'
  | 'analytics'
  | 'settings'
  | 'profile'
  | 'billing'
  | 'marketplace'
  | 'ai-tutor'
  | 'study-planner'
  | 'resources';
