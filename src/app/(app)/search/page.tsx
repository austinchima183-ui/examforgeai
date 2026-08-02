'use client'

import { useState, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Loader2, Search, School, GraduationCap, BookOpen, Users, HelpCircle, FileText, Store, Bell, CreditCard } from 'lucide-react'
import Link from 'next/link'
import type { SearchResult } from '@/lib/services/search-service'

// ============================================================================
// ExamForge AI — Global Search Page
// ============================================================================
// Client component with live Supabase search across all entities.
// ============================================================================

const iconMap: Record<string, typeof School> = {
  School,
  GraduationCap,
  BookOpen,
  Users,
  HelpCircle,
  FileText,
  Store,
  Bell,
  CreditCard,
}

const typeLabelMap: Record<string, string> = {
  school: 'School',
  student: 'Student',
  teacher: 'Teacher',
  parent: 'Parent',
  question: 'Question',
  exam: 'Exam',
  marketplace: 'Marketplace',
  notification: 'Notification',
  payment: 'Payment',
}

const typeColorMap: Record<string, string> = {
  school: 'text-blue-600 bg-blue-50',
  student: 'text-emerald-600 bg-emerald-50',
  teacher: 'text-purple-600 bg-purple-50',
  parent: 'text-teal-600 bg-teal-50',
  question: 'text-amber-600 bg-amber-50',
  exam: 'text-indigo-600 bg-indigo-50',
  marketplace: 'text-pink-600 bg-pink-50',
  notification: 'text-gray-600 bg-gray-50',
  payment: 'text-green-600 bg-green-50',
}

export default function SearchPage() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<SearchResult[]>([])
  const [loading, setLoading] = useState(false)
  const [searched, setSearched] = useState(false)

  const handleSearch = useCallback(async () => {
    if (!query.trim() || query.trim().length < 2) return

    setLoading(true)
    try {
      const res = await fetch(`/api/search?q=${encodeURIComponent(query.trim())}`)
      if (!res.ok) throw new Error('Search failed')
      const data = await res.json()
      setResults(data.results ?? [])
      setSearched(true)
    } catch {
      setResults([])
      setSearched(true)
    } finally {
      setLoading(false)
    }
  }, [query])

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') handleSearch()
  }

  // Group results by type
  const groupedResults = results.reduce<Record<string, SearchResult[]>>((acc, result) => {
    if (!acc[result.type]) acc[result.type] = []
    acc[result.type].push(result)
    return acc
  }, {})

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Search</h1>
        <p className="text-sm text-muted-foreground">
          Search across schools, students, teachers, questions, exams, and more.
        </p>
      </div>

      {/* Search Input */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Search schools, students, teachers, questions, exams..."
          className="pl-9 h-12 text-base"
          autoFocus
        />
        <Button
          onClick={handleSearch}
          disabled={loading || query.trim().length < 2}
          className="absolute right-1.5 top-1/2 -translate-y-1/2 h-9"
          size="sm"
        >
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Search'}
        </Button>
      </div>

      {/* Results */}
      {loading && (
        <div className="flex items-center justify-center p-12">
          <div className="flex flex-col items-center gap-3">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
            <p className="text-sm text-muted-foreground">Searching...</p>
          </div>
        </div>
      )}

      {!loading && searched && results.length === 0 && (
        <Card>
          <CardContent className="p-8 text-center">
            <div className="flex justify-center mb-4">
              <div className="h-16 w-16 rounded-full bg-muted flex items-center justify-center">
                <Search className="h-8 w-8 text-muted-foreground" />
              </div>
            </div>
            <h3 className="text-lg font-medium">No results found</h3>
            <p className="text-sm text-muted-foreground mt-1">
              No results matched &ldquo;{query}&rdquo;. Try different keywords.
            </p>
          </CardContent>
        </Card>
      )}

      {!loading && results.length > 0 && (
        <div className="space-y-6">
          <p className="text-sm text-muted-foreground">
            {results.length} result{results.length !== 1 ? 's' : ''} found for &ldquo;{query}&rdquo;
          </p>

          {Object.entries(groupedResults).map(([type, items]) => {
            const Icon = iconMap[type] ?? Search
            const colorClass = typeColorMap[type] ?? 'text-gray-600 bg-gray-50'

            return (
              <div key={type}>
                <h2 className="text-sm font-medium text-muted-foreground mb-3 flex items-center gap-2">
                  <Icon className="h-4 w-4" />
                  {typeLabelMap[type] ?? type} ({items.length})
                </h2>
                <div className="space-y-2">
                  {items.map((item) => (
                    <Link key={item.id} href={item.href}>
                      <Card className="hover:shadow-md transition-shadow cursor-pointer">
                        <CardContent className="p-4 flex items-center gap-3">
                          <div className={`h-9 w-9 rounded-lg flex items-center justify-center shrink-0 ${colorClass}`}>
                            <Icon className="h-4 w-4" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-medium truncate">{item.title}</p>
                            <p className="text-xs text-muted-foreground truncate">{item.subtitle}</p>
                          </div>
                          <Badge variant="outline" className="shrink-0 text-[10px]">
                            {typeLabelMap[item.type] ?? item.type}
                          </Badge>
                        </CardContent>
                      </Card>
                    </Link>
                  ))}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {!searched && !loading && (
        <Card>
          <CardContent className="p-8 text-center">
            <div className="flex justify-center mb-4">
              <div className="h-16 w-16 rounded-full bg-muted flex items-center justify-center">
                <Search className="h-8 w-8 text-muted-foreground" />
              </div>
            </div>
            <h3 className="text-lg font-medium">Start searching</h3>
            <p className="text-sm text-muted-foreground mt-1">
              Search across schools, students, teachers, parents, questions, exams, results, marketplace, and payments.
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
