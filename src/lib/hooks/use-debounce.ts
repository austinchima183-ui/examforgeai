// ============================================================================
// ExamForge AI — Debounce Hook
// ============================================================================
// Generic debounce hook that delays updating a value until a specified
// delay has passed since the last change. Useful for search inputs,
// resize handlers, and other high-frequency events.
// ============================================================================

import { useState, useEffect, useCallback } from 'react'

/**
 * Debounce a value by a specified delay.
 *
 * @param value - The value to debounce
 * @param delay - Delay in milliseconds (default: 300)
 * @returns The debounced value
 *
 * @example
 * ```tsx
 * const [search, setSearch] = useState('')
 * const debouncedSearch = useDebounce(search, 500)
 *
 * useEffect(() => {
 *   // API call with debouncedSearch
 * }, [debouncedSearch])
 * ```
 */
export function useDebounce<T>(value: T, delay: number = 300): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => {
      clearTimeout(timer)
    }
  }, [value, delay])

  return debouncedValue
}

/**
 * Returns a debounced callback function.
 *
 * @param callback - The function to debounce
 * @param delay - Delay in milliseconds (default: 300)
 * @returns A debounced version of the callback
 *
 * @example
 * ```tsx
 * const handleSearch = useDebouncedCallback((query: string) => {
 *   fetchResults(query)
 * }, 500)
 * ```
 */
export function useDebouncedCallback<T extends (...args: unknown[]) => unknown>(
  callback: T,
  delay: number = 300
): T {
  const [timer, setTimer] = useState<NodeJS.Timeout | null>(null)

  const debouncedCallback = useCallback(
    (...args: unknown[]) => {
      if (timer) clearTimeout(timer)
      const newTimer = setTimeout(() => {
        callback(...args)
      }, delay)
      setTimer(newTimer)
    },
    [callback, delay, timer]
  ) as T

  useEffect(() => {
    return () => {
      if (timer) clearTimeout(timer)
    }
  }, [timer])

  return debouncedCallback
}
