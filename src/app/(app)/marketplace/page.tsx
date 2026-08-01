import { Store, Search, Star, Download, ShoppingCart, Sparkles, TrendingUp, BookOpen } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

// ============================================================================
// ExamForge AI — Marketplace Page
// ============================================================================
// Server Component. Displays a marketplace with search and category
// filters, product grid, and featured section.
// ============================================================================

// ──────────────────────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────────────────────

interface MarketplaceItem {
  id: string
  title: string
  description: string
  author: string
  category: 'exam_pack' | 'question_set' | 'template' | 'course' | 'ai_tool'
  price: number
  rating: number
  reviewCount: number
  downloadCount: number
  isFeatured: boolean
  isNew: boolean
  thumbnail?: string
}

// ──────────────────────────────────────────────────────────────
// Mock Data
// ──────────────────────────────────────────────────────────────

const FEATURED_ITEMS: MarketplaceItem[] = [
  {
    id: 'f1',
    title: 'WAEC Mathematics Complete Pack',
    description: 'Comprehensive question bank covering all WAEC Mathematics topics with 500+ practice questions and solutions.',
    author: 'ExamForge Official',
    category: 'exam_pack',
    price: 29.99,
    rating: 4.9,
    reviewCount: 234,
    downloadCount: 1520,
    isFeatured: true,
    isNew: false,
  },
  {
    id: 'f2',
    title: 'NECO Science Bundle',
    description: 'All-in-one science bundle covering Physics, Chemistry, and Biology for NECO examinations.',
    author: 'Dr. Akinola',
    category: 'exam_pack',
    price: 49.99,
    rating: 4.8,
    reviewCount: 189,
    downloadCount: 980,
    isFeatured: true,
    isNew: true,
  },
  {
    id: 'f3',
    title: 'AI Question Generator Pro',
    description: 'Generate unlimited exam questions with AI. Supports multiple subjects, difficulty levels, and question types.',
    author: 'ExamForge AI',
    category: 'ai_tool',
    price: 19.99,
    rating: 4.7,
    reviewCount: 312,
    downloadCount: 2100,
    isFeatured: true,
    isNew: false,
  },
]

const ALL_ITEMS: MarketplaceItem[] = [
  ...FEATURED_ITEMS,
  {
    id: '4',
    title: 'JAMB English Past Questions',
    description: '10 years of JAMB English past questions with detailed explanations and answers.',
    author: 'EduTech Solutions',
    category: 'question_set',
    price: 14.99,
    rating: 4.5,
    reviewCount: 156,
    downloadCount: 890,
    isFeatured: false,
    isNew: false,
  },
  {
    id: '5',
    title: 'Custom Exam Template Pack',
    description: 'Professional exam templates for all subjects. Includes answer sheets and marking guides.',
    author: 'TemplatePro',
    category: 'template',
    price: 9.99,
    rating: 4.3,
    reviewCount: 87,
    downloadCount: 560,
    isFeatured: false,
    isNew: true,
  },
  {
    id: '6',
    title: 'SSCE Physics Masterclass',
    description: 'Complete online course covering all SSCE Physics topics with video lessons and practice exams.',
    author: 'Prof. Okafor',
    category: 'course',
    price: 39.99,
    rating: 4.6,
    reviewCount: 203,
    downloadCount: 740,
    isFeatured: false,
    isNew: false,
  },
  {
    id: '7',
    title: 'Primary School Assessment Pack',
    description: 'Age-appropriate assessment tools for primary school students across all core subjects.',
    author: 'EarlyEdu',
    category: 'exam_pack',
    price: 24.99,
    rating: 4.4,
    reviewCount: 95,
    downloadCount: 430,
    isFeatured: false,
    isNew: false,
  },
  {
    id: '8',
    title: 'AI Essay Grader',
    description: 'Automatically grade student essays with AI-powered feedback and rubric alignment.',
    author: 'ExamForge AI',
    category: 'ai_tool',
    price: 12.99,
    rating: 4.2,
    reviewCount: 67,
    downloadCount: 320,
    isFeatured: false,
    isNew: true,
  },
  {
    id: '9',
    title: 'Chemistry Lab Practical Guide',
    description: 'Step-by-step guide for chemistry practicals with safety tips and common exam questions.',
    author: 'LabMaster',
    category: 'course',
    price: 19.99,
    rating: 4.1,
    reviewCount: 45,
    downloadCount: 210,
    isFeatured: false,
    isNew: false,
  },
]

// ──────────────────────────────────────────────────────────────
// Category Label Map
// ──────────────────────────────────────────────────────────────

const categoryLabels: Record<MarketplaceItem['category'], string> = {
  exam_pack: 'Exam Pack',
  question_set: 'Question Set',
  template: 'Template',
  course: 'Course',
  ai_tool: 'AI Tool',
}

const categoryColors: Record<MarketplaceItem['category'], 'default' | 'secondary' | 'outline'> = {
  exam_pack: 'default',
  question_set: 'secondary',
  template: 'outline',
  course: 'secondary',
  ai_tool: 'default',
}

// ──────────────────────────────────────────────────────────────
// Product Card Component
// ──────────────────────────────────────────────────────────────

function ProductCard({ item }: { item: MarketplaceItem }) {
  return (
    <Card className="group relative overflow-hidden transition-all hover:shadow-md">
      {/* Thumbnail placeholder */}
      <div className="aspect-video bg-gradient-to-br from-primary/10 to-primary/5 flex items-center justify-center">
        <Store className="h-12 w-12 text-primary/30" />
      </div>

      {/* Badges */}
      <div className="absolute top-2 left-2 flex gap-1">
        {item.isNew && (
          <Badge variant="default" className="text-[10px] gap-0.5">
            <Sparkles className="h-3 w-3" />
            New
          </Badge>
        )}
        {item.isFeatured && (
          <Badge variant="secondary" className="text-[10px] gap-0.5">
            <TrendingUp className="h-3 w-3" />
            Featured
          </Badge>
        )}
      </div>

      <CardHeader className="p-4 pb-2">
        <div className="flex items-start justify-between gap-2">
          <div className="space-y-1 min-w-0">
            <CardTitle className="text-sm leading-tight line-clamp-2">{item.title}</CardTitle>
            <p className="text-xs text-muted-foreground">{item.author}</p>
          </div>
        </div>
        <Badge variant={categoryColors[item.category]} className="text-[10px] w-fit">
          {categoryLabels[item.category]}
        </Badge>
      </CardHeader>

      <CardContent className="p-4 pt-0">
        <p className="text-xs text-muted-foreground line-clamp-2 mb-3">{item.description}</p>

        {/* Rating & Downloads */}
        <div className="flex items-center gap-3 text-xs text-muted-foreground mb-3">
          <span className="flex items-center gap-1">
            <Star className="h-3 w-3 fill-amber-400 text-amber-400" />
            {item.rating} ({item.reviewCount})
          </span>
          <span className="flex items-center gap-1">
            <Download className="h-3 w-3" />
            {item.downloadCount.toLocaleString()}
          </span>
        </div>

        {/* Price & Action */}
        <div className="flex items-center justify-between">
          <span className="text-lg font-bold">
            {item.price === 0 ? 'Free' : `$${item.price}`}
          </span>
          <Button size="sm" className="gap-1.5">
            <ShoppingCart className="h-3.5 w-3.5" />
            {item.price === 0 ? 'Get' : 'Buy'}
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}

// ──────────────────────────────────────────────────────────────
// Page Component
// ──────────────────────────────────────────────────────────────

export default function MarketplacePage() {
  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Marketplace</h1>
          <p className="text-sm text-muted-foreground">
            Discover and purchase educational content, exam packs, and AI tools.
          </p>
        </div>
      </div>

      {/* Search & Filters */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search marketplace..."
            className="pl-9 h-9"
          />
        </div>
        <div className="flex items-center gap-2">
          <Select defaultValue="all">
            <SelectTrigger className="h-9 w-[160px]">
              <SelectValue placeholder="Category" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Categories</SelectItem>
              <SelectItem value="exam_pack">Exam Packs</SelectItem>
              <SelectItem value="question_set">Question Sets</SelectItem>
              <SelectItem value="template">Templates</SelectItem>
              <SelectItem value="course">Courses</SelectItem>
              <SelectItem value="ai_tool">AI Tools</SelectItem>
            </SelectContent>
          </Select>
          <Select defaultValue="popular">
            <SelectTrigger className="h-9 w-[140px]">
              <SelectValue placeholder="Sort by" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="popular">Most Popular</SelectItem>
              <SelectItem value="newest">Newest</SelectItem>
              <SelectItem value="rating">Highest Rated</SelectItem>
              <SelectItem value="price_low">Price: Low</SelectItem>
              <SelectItem value="price_high">Price: High</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Featured Section */}
      <section>
        <div className="flex items-center gap-2 mb-4">
          <Sparkles className="h-5 w-5 text-primary" />
          <h2 className="text-lg font-semibold">Featured</h2>
        </div>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURED_ITEMS.map((item) => (
            <ProductCard key={item.id} item={item} />
          ))}
        </div>
      </section>

      {/* All Products */}
      <Tabs defaultValue="all" className="space-y-4">
        <TabsList>
          <TabsTrigger value="all">All</TabsTrigger>
          <TabsTrigger value="exam_pack">Exam Packs</TabsTrigger>
          <TabsTrigger value="question_set">Question Sets</TabsTrigger>
          <TabsTrigger value="template">Templates</TabsTrigger>
          <TabsTrigger value="course">Courses</TabsTrigger>
          <TabsTrigger value="ai_tool">AI Tools</TabsTrigger>
        </TabsList>

        <TabsContent value="all">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {ALL_ITEMS.map((item) => (
              <ProductCard key={item.id} item={item} />
            ))}
          </div>
        </TabsContent>

        <TabsContent value="exam_pack">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {ALL_ITEMS.filter((item) => item.category === 'exam_pack').map((item) => (
              <ProductCard key={item.id} item={item} />
            ))}
          </div>
        </TabsContent>

        <TabsContent value="question_set">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {ALL_ITEMS.filter((item) => item.category === 'question_set').map((item) => (
              <ProductCard key={item.id} item={item} />
            ))}
          </div>
        </TabsContent>

        <TabsContent value="template">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {ALL_ITEMS.filter((item) => item.category === 'template').map((item) => (
              <ProductCard key={item.id} item={item} />
            ))}
          </div>
        </TabsContent>

        <TabsContent value="course">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {ALL_ITEMS.filter((item) => item.category === 'course').map((item) => (
              <ProductCard key={item.id} item={item} />
            ))}
          </div>
        </TabsContent>

        <TabsContent value="ai_tool">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {ALL_ITEMS.filter((item) => item.category === 'ai_tool').map((item) => (
              <ProductCard key={item.id} item={item} />
            ))}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}
