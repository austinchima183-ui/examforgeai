// ============================================================================
// ExamForge AI — Marketplace Data Service
// ============================================================================
// Server-side data fetching for the marketplace.
// All queries use the Supabase server client with cookie-based auth.
// ============================================================================

import { createClient } from '@/lib/supabase/server'

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

export interface MarketplaceProduct {
  id: string
  title: string
  description: string
  author: string
  category: string
  price: number
  rating: number
  reviewCount: number
  downloadCount: number
  isFeatured: boolean
  isNew: boolean
  thumbnail: string | null
  createdAt: string
}

export interface MarketplacePageData {
  products: MarketplaceProduct[]
  categories: string[]
  featured: MarketplaceProduct[]
}

// ──────────────────────────────────────────────────────────────
// Marketplace Service
// ──────────────────────────────────────────────────────────────

export async function getMarketplaceData(): Promise<MarketplacePageData> {
  const supabase = await createClient()

  // Fetch all published products
  const { data: products, error } = await supabase
    .from('marketplace_products')
    .select(`
      id,
      title,
      description,
      author_id,
      category,
      price,
      currency,
      rating,
      review_count,
      download_count,
      is_featured,
      thumbnail_url,
      status,
      created_at
    `)
    .eq('status', 'published')
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error fetching marketplace products:', error)
    return { products: [], categories: [], featured: [] }
  }

  // Get author names
  const authorIds = [...new Set((products ?? []).map(p => p.author_id).filter(Boolean))] as string[]
  const { data: authors } = await supabase
    .from('profiles')
    .select('id, full_name')
    .in('id', authorIds.length > 0 ? authorIds : ['__none__'])

  const authorMap = new Map<string, string>()
  for (const a of authors ?? []) {
    authorMap.set(a.id, a.full_name ?? 'Unknown Author')
  }

  // Determine which products are "new" (created in last 7 days)
  const sevenDaysAgo = new Date(Date.now() - 7 * 86400000)

  const mapped: MarketplaceProduct[] = (products ?? []).map(p => ({
    id: p.id,
    title: p.title,
    description: p.description ?? '',
    author: p.author_id ? (authorMap.get(p.author_id) ?? 'Unknown Author') : 'ExamForge Team',
    category: p.category ?? 'exam_pack',
    price: p.price ?? 0,
    rating: p.rating ?? 0,
    reviewCount: p.review_count ?? 0,
    downloadCount: p.download_count ?? 0,
    isFeatured: p.is_featured ?? false,
    isNew: new Date(p.created_at) > sevenDaysAgo,
    thumbnail: p.thumbnail_url,
    createdAt: p.created_at,
  }))

  const categories = [...new Set(mapped.map(p => p.category))].sort()
  const featured = mapped.filter(p => p.isFeatured)

  return {
    products: mapped,
    categories,
    featured,
  }
}
