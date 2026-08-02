import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { ROUTES } from '@/lib/constants/routes'
import { Store, Search, Star, Download, ShoppingBag } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { getMarketplaceData } from '@/lib/services/marketplace-service'
import type { MarketplaceProduct } from '@/lib/services/marketplace-service'

export const dynamic = 'force-dynamic'

// ============================================================================
// ExamForge AI — Marketplace Page
// ============================================================================
// Server Component. Displays marketplace products from Supabase.
// No mock data. All products are live.
// ============================================================================

const categoryLabelMap: Record<string, string> = {
  exam_pack: 'Exam Packs',
  question_set: 'Question Sets',
  template: 'Templates',
  course: 'Courses',
  ai_tool: 'AI Tools',
}

function formatPrice(price: number): string {
  return new Intl.NumberFormat('en-NG', {
    style: 'currency',
    currency: 'NGN',
    minimumFractionDigits: 0,
  }).format(price)
}

function ProductCard({ product }: { product: MarketplaceProduct }) {
  return (
    <Card className="hover:shadow-md transition-shadow">
      <CardContent className="p-4">
        <div className="flex items-start justify-between gap-2 mb-3">
          <div className="h-10 w-10 rounded-lg bg-primary/10 flex items-center justify-center shrink-0">
            <Store className="h-5 w-5 text-primary" />
          </div>
          <div className="flex items-center gap-1">
            {product.isFeatured && (
              <Badge variant="default" className="text-[10px] px-1.5 py-0">Featured</Badge>
            )}
            {product.isNew && (
              <Badge variant="secondary" className="text-[10px] px-1.5 py-0">New</Badge>
            )}
          </div>
        </div>

        <h3 className="font-medium text-sm mb-1 line-clamp-2">{product.title}</h3>
        <p className="text-xs text-muted-foreground mb-3 line-clamp-2">{product.description}</p>

        <div className="flex items-center gap-2 mb-3">
          <div className="flex items-center gap-0.5">
            <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
            <span className="text-xs font-medium">{product.rating.toFixed(1)}</span>
          </div>
          <span className="text-xs text-muted-foreground">({product.reviewCount})</span>
          <span className="text-xs text-muted-foreground ml-auto">
            <Download className="h-3 w-3 inline mr-0.5" />
            {product.downloadCount}
          </span>
        </div>

        <div className="flex items-center justify-between">
          <span className="font-semibold text-sm">{product.price > 0 ? formatPrice(product.price) : 'Free'}</span>
          <Button size="sm" variant={product.price > 0 ? 'default' : 'outline'}>
            {product.price > 0 ? 'Buy' : 'Get'}
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}

export default async function MarketplacePage() {
  const supabase = await createClient()

  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect(ROUTES.LOGIN)
  }

  // Fetch live data from Supabase
  const data = await getMarketplaceData()

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Marketplace</h1>
          <p className="text-sm text-muted-foreground">
            Browse and purchase educational content, exam packs, and AI tools.
          </p>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search marketplace..."
          className="pl-9 h-10"
        />
      </div>

      {/* Featured Products */}
      {data.featured.length > 0 && (
        <div>
          <h2 className="text-lg font-semibold mb-4">Featured</h2>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {data.featured.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        </div>
      )}

      {/* All Products */}
      <Tabs defaultValue="all">
        <TabsList>
          <TabsTrigger value="all">All ({data.products.length})</TabsTrigger>
          {data.categories.map((cat) => (
            <TabsTrigger key={cat} value={cat}>
              {categoryLabelMap[cat] ?? cat}
            </TabsTrigger>
          ))}
        </TabsList>

        <TabsContent value="all" className="mt-4">
          {data.products.length > 0 ? (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {data.products.map((product) => (
                <ProductCard key={product.id} product={product} />
              ))}
            </div>
          ) : (
            <Card>
              <CardContent className="p-8 text-center">
                <div className="flex justify-center mb-4">
                  <div className="h-16 w-16 rounded-full bg-muted flex items-center justify-center">
                    <ShoppingBag className="h-8 w-8 text-muted-foreground" />
                  </div>
                </div>
                <h3 className="text-lg font-medium">No products available</h3>
                <p className="text-sm text-muted-foreground mt-1">
                  Marketplace products will appear here once they are published.
                </p>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        {data.categories.map((cat) => (
          <TabsContent key={cat} value={cat} className="mt-4">
            {data.products.filter(p => p.category === cat).length > 0 ? (
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {data.products
                  .filter(p => p.category === cat)
                  .map((product) => (
                    <ProductCard key={product.id} product={product} />
                  ))}
              </div>
            ) : (
              <Card>
                <CardContent className="p-8 text-center">
                  <p className="text-sm text-muted-foreground">
                    No {categoryLabelMap[cat]?.toLowerCase() ?? cat} available yet.
                  </p>
                </CardContent>
              </Card>
            )}
          </TabsContent>
        ))}
      </Tabs>
    </div>
  )
}
