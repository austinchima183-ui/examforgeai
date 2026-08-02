// ============================================================================
// ExamForge AI — Offline Detection Hook
// ============================================================================
// Detects the browser's online/offline status using navigator.onLine
// and listens for online/offline events to update in real-time.
// ============================================================================

import { useState, useEffect, useCallback } from 'react'

interface OfflineState {
  /** Whether the browser is currently offline */
  isOffline: boolean
  /** Whether the browser is currently online */
  isOnline: boolean
  /** Timestamp of the last online-to-offline transition */
  lastOfflineAt: Date | null
  /** Timestamp of the last offline-to-online transition */
  lastOnlineAt: Date | null
}

/**
 * Detect the browser's online/offline status.
 *
 * Uses `navigator.onLine` for the initial state and subscribes to
 * `online` / `offline` window events for real-time updates.
 *
 * @returns Object with current status and transition timestamps
 *
 * @example
 * ```tsx
 * const { isOffline, isOnline } = useOffline()
 *
 * if (isOffline) {
 *   return <OfflineBanner />
 * }
 * ```
 */
export function useOffline(): OfflineState {
  const [state, setState] = useState<OfflineState>(() => ({
    isOffline: typeof window === 'undefined' ? false : !navigator.onLine,
    isOnline: typeof window === 'undefined' ? true : navigator.onLine,
    lastOfflineAt: null,
    lastOnlineAt: null,
  }))

  const handleOnline = useCallback(() => {
    setState((prev) => ({
      ...prev,
      isOffline: false,
      isOnline: true,
      lastOnlineAt: new Date(),
    }))
  }, [])

  const handleOffline = useCallback(() => {
    setState((prev) => ({
      ...prev,
      isOffline: true,
      isOnline: false,
      lastOfflineAt: new Date(),
    }))
  }, [])

  useEffect(() => {
    if (typeof window === 'undefined') return

    // Subscribe to events
    window.addEventListener('online', handleOnline)
    window.addEventListener('offline', handleOffline)

    return () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }, [handleOnline, handleOffline])

  return state
}
