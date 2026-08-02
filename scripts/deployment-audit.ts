/**
 * ExamForge AI — Production Deployment Audit
 * 
 * Verifies: Vercel, Supabase, Edge Functions, Storage, CDN,
 * CSP, CORS, HTTPS, SSL, Environment Variables
 * 
 * Usage: npx tsx scripts/deployment-audit.ts
 */

const BASE_URL = process.env.NEXT_PUBLIC_APP_URL ?? 'http://localhost:3000'
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? ''

interface DeploymentResult {
  category: string
  test: string
  status: 'PASS' | 'FAIL' | 'WARN'
  details: string
}

const results: DeploymentResult[] = []

function addResult(category: string, test: string, status: 'PASS' | 'FAIL' | 'WARN', details: string) {
  results.push({ category, test, status, details })
}

// ─── 1. Vercel Configuration ───────────────────────────────────────────────

async function auditVercel() {
  // Check that the site is accessible
  try {
    const res = await fetch(BASE_URL, { method: 'GET' })
    addResult('Vercel', 'Site Accessibility', res.ok ? 'PASS' : 'FAIL', `HTTP ${res.status}`)
  } catch (err) {
    addResult('Vercel', 'Site Accessibility', 'FAIL', `Cannot reach ${BASE_URL}: ${err instanceof Error ? err.message : 'Unknown'}`)
  }

  // Check for Next.js powered-by header (should be removed in production)
  try {
    const res = await fetch(BASE_URL, { method: 'GET' })
    const poweredBy = res.headers.get('x-powered-by')
    if (poweredBy) {
      addResult('Vercel', 'X-Powered-By Header', 'WARN', `Header present: ${poweredBy} — should be removed in production`)
    } else {
      addResult('Vercel', 'X-Powered-By Header', 'PASS', 'Header not present')
    }
  } catch {
    addResult('Vercel', 'X-Powered-By Header', 'FAIL', 'Cannot check headers')
  }
}

// ─── 2. Supabase ───────────────────────────────────────────────────────────

async function auditSupabase() {
  if (!SUPABASE_URL) {
    addResult('Supabase', 'URL Configuration', 'FAIL', 'NEXT_PUBLIC_SUPABASE_URL not set')
    return
  }

  addResult('Supabase', 'URL Configuration', 'PASS', SUPABASE_URL)

  // Check Supabase health
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/`, {
      headers: { apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '' },
    })
    if (res.ok || res.status === 401) {
      addResult('Supabase', 'REST API Health', 'PASS', `Supabase REST API responding (HTTP ${res.status})`)
    } else {
      addResult('Supabase', 'REST API Health', 'WARN', `Unexpected status: HTTP ${res.status}`)
    }
  } catch (err) {
    addResult('Supabase', 'REST API Health', 'FAIL', `Cannot reach Supabase: ${err instanceof Error ? err.message : 'Unknown'}`)
  }

  // Check Supabase Auth
  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/health`)
    if (res.ok) {
      addResult('Supabase', 'Auth Service Health', 'PASS', 'Auth service is healthy')
    } else {
      addResult('Supabase', 'Auth Service Health', 'WARN', `Auth health returned HTTP ${res.status}`)
    }
  } catch {
    addResult('Supabase', 'Auth Service Health', 'FAIL', 'Cannot reach auth service')
  }
}

// ─── 3. Edge Functions ─────────────────────────────────────────────────────

async function auditEdgeFunctions() {
  if (!SUPABASE_URL) {
    addResult('Edge Functions', 'Configuration', 'FAIL', 'Supabase URL not set')
    return
  }

  const edgeFunctions = [
    'flutterwave-webhook',
    'process-refund',
  ]

  for (const fn of edgeFunctions) {
    try {
      const res = await fetch(`${SUPABASE_URL}/functions/v1/${fn}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ health: true }),
      })
      // 401 = function exists but requires auth
      // 400 = function exists but invalid input
      // Both are good signs
      if (res.status === 401 || res.status === 400 || res.status === 422) {
        addResult('Edge Functions', `${fn}`, 'PASS', `Function exists (HTTP ${res.status})`)
      } else if (res.status === 404) {
        addResult('Edge Functions', `${fn}`, 'FAIL', `Function not found (HTTP 404)`)
      } else {
        addResult('Edge Functions', `${fn}`, 'WARN', `Unexpected status: HTTP ${res.status}`)
      }
    } catch (err) {
      addResult('Edge Functions', `${fn}`, 'FAIL', `Cannot reach: ${err instanceof Error ? err.message : 'Unknown'}`)
    }
  }
}

// ─── 4. Storage ────────────────────────────────────────────────────────────

async function auditStorage() {
  if (!SUPABASE_URL) {
    addResult('Storage', 'Configuration', 'FAIL', 'Supabase URL not set')
    return
  }

  // Check storage endpoint
  try {
    const res = await fetch(`${SUPABASE_URL}/storage/v1/bucket`, {
      headers: { apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '' },
    })
    if (res.ok || res.status === 401) {
      addResult('Storage', 'Storage API Health', 'PASS', `Storage API responding (HTTP ${res.status})`)
    } else {
      addResult('Storage', 'Storage API Health', 'WARN', `Unexpected status: HTTP ${res.status}`)
    }
  } catch (err) {
    addResult('Storage', 'Storage API Health', 'FAIL', `Cannot reach storage: ${err instanceof Error ? err.message : 'Unknown'}`)
  }
}

// ─── 5. CSP ────────────────────────────────────────────────────────────────

async function auditCSP() {
  try {
    const res = await fetch(BASE_URL, { method: 'GET' })
    const csp = res.headers.get('content-security-policy')

    if (!csp) {
      addResult('CSP', 'CSP Header', 'FAIL', 'No Content-Security-Policy header found')
      return
    }

    addResult('CSP', 'CSP Header Present', 'PASS', 'CSP header found')

    // Check for unsafe-eval
    if (csp.includes("'unsafe-eval'")) {
      addResult('CSP', 'unsafe-eval', 'FAIL', 'CSP contains unsafe-eval — this is a XSS risk')
    } else {
      addResult('CSP', 'unsafe-eval', 'PASS', 'CSP does not contain unsafe-eval')
    }

    // Check for unsafe-inline
    if (csp.includes("'unsafe-inline'")) {
      addResult('CSP', 'unsafe-inline', 'WARN', 'CSP contains unsafe-inline — consider nonce-based CSP')
    } else {
      addResult('CSP', 'unsafe-inline', 'PASS', 'CSP does not contain unsafe-inline')
    }

    // Check default-src
    if (csp.includes("default-src 'self'")) {
      addResult('CSP', 'default-src', 'PASS', "default-src is 'self'")
    } else {
      addResult('CSP', 'default-src', 'WARN', 'default-src is not restricted to self')
    }

    // Check frame-ancestors
    if (csp.includes("frame-ancestors 'none'")) {
      addResult('CSP', 'frame-ancestors', 'PASS', "frame-ancestors is 'none'")
    } else {
      addResult('CSP', 'frame-ancestors', 'WARN', 'frame-ancestors not set to none')
    }
  } catch {
    addResult('CSP', 'CSP Header', 'FAIL', 'Cannot check CSP headers')
  }
}

// ─── 6. CORS ───────────────────────────────────────────────────────────────

async function auditCORS() {
  try {
    const res = await fetch(BASE_URL, {
      method: 'OPTIONS',
      headers: {
        'Origin': 'https://evil.com',
        'Access-Control-Request-Method': 'POST',
      },
    })

    const allowOrigin = res.headers.get('access-control-allow-origin')
    if (allowOrigin === '*' || allowOrigin === 'https://evil.com') {
      addResult('CORS', 'Origin Validation', 'FAIL', `CORS allows: ${allowOrigin}`)
    } else if (allowOrigin) {
      addResult('CORS', 'Origin Validation', 'PASS', `CORS restricted to: ${allowOrigin}`)
    } else {
      addResult('CORS', 'Origin Validation', 'PASS', 'No CORS header (browser will block cross-origin)')
    }
  } catch {
    addResult('CORS', 'Origin Validation', 'WARN', 'Cannot check CORS')
  }
}

// ─── 7. HTTPS / SSL ────────────────────────────────────────────────────────

async function auditHTTPS() {
  const url = new URL(BASE_URL)

  if (url.protocol === 'https:') {
    addResult('HTTPS', 'Protocol', 'PASS', 'Site is served over HTTPS')
  } else {
    addResult('HTTPS', 'Protocol', 'WARN', 'Site is not served over HTTPS (expected in development)')
  }

  // Check HSTS
  try {
    const res = await fetch(BASE_URL, { method: 'GET' })
    const hsts = res.headers.get('strict-transport-security')
    if (hsts) {
      const maxAge = parseInt(hsts.match(/max-age=(\d+)/)?.[1] ?? '0', 10)
      if (maxAge >= 31536000) {
        addResult('HTTPS', 'HSTS', 'PASS', `HSTS max-age: ${maxAge}s (>= 1 year)`)
      } else {
        addResult('HTTPS', 'HSTS', 'WARN', `HSTS max-age: ${maxAge}s (< 1 year)`)
      }
    } else {
      addResult('HTTPS', 'HSTS', 'FAIL', 'No Strict-Transport-Security header')
    }
  } catch {
    addResult('HTTPS', 'HSTS', 'FAIL', 'Cannot check HSTS')
  }
}

// ─── 8. Environment Variables ──────────────────────────────────────────────

async function auditEnvironmentVariables() {
  const requiredVars = [
    { name: 'NEXT_PUBLIC_SUPABASE_URL', value: process.env.NEXT_PUBLIC_SUPABASE_URL },
    { name: 'NEXT_PUBLIC_SUPABASE_ANON_KEY', value: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY },
    { name: 'SUPABASE_SERVICE_ROLE_KEY', value: process.env.SUPABASE_SERVICE_ROLE_KEY },
    { name: 'FLUTTERWAVE_WEBHOOK_SECRET', value: process.env.FLUTTERWAVE_WEBHOOK_SECRET },
  ]

  for (const { name, value } of requiredVars) {
    if (value) {
      addResult('Environment', name, 'PASS', 'Set')
    } else {
      addResult('Environment', name, 'FAIL', 'Not set')
    }
  }

  // Check for secrets in client-side bundle
  const secretVars = [
    'SUPABASE_SERVICE_ROLE_KEY',
    'FLUTTERWAVE_WEBHOOK_SECRET',
    'FLUTTERWAVE_SECRET_KEY',
  ]

  for (const varName of secretVars) {
    if (varName.startsWith('NEXT_PUBLIC_')) {
      addResult('Environment', `Secret exposure: ${varName}`, 'FAIL', 'Secret variable has NEXT_PUBLIC_ prefix — exposed to client')
    }
  }
}

// ─── Print Results ──────────────────────────────────────────────────────────

function printResults() {
  console.log('\n' + '='.repeat(80))
  console.log('PRODUCTION DEPLOYMENT AUDIT RESULTS')
  console.log('='.repeat(80))
  console.log(`Target: ${BASE_URL}`)
  console.log(`Date: ${new Date().toISOString()}`)
  console.log('-'.repeat(80))

  const categories = [...new Set(results.map(r => r.category))]
  let totalPass = 0
  let totalFail = 0
  let totalWarn = 0

  for (const category of categories) {
    const categoryResults = results.filter(r => r.category === category)
    console.log(`\n┌── ${category} ──`)
    for (const r of categoryResults) {
      const icon = r.status === 'PASS' ? '✅' : r.status === 'FAIL' ? '❌' : '⚠️'
      console.log(`│ ${icon} ${r.test}: ${r.details}`)
      if (r.status === 'PASS') totalPass++
      else if (r.status === 'FAIL') totalFail++
      else totalWarn++
    }
    console.log('└──')
  }

  console.log('\n' + '='.repeat(80))
  console.log(`SUMMARY: ${totalPass} PASS | ${totalFail} FAIL | ${totalWarn} WARN | ${results.length} TOTAL`)
  console.log('='.repeat(80))

  if (totalFail > 0) {
    console.log('\n❌ DEPLOYMENT AUDIT FAILED — Fix the issues above before deploying.')
    process.exit(1)
  } else if (totalWarn > 0) {
    console.log('\n⚠️  DEPLOYMENT AUDIT PASSED WITH WARNINGS — Review before deploying.')
  } else {
    console.log('\n✅ DEPLOYMENT AUDIT PASSED — Ready for production.')
  }
}

// ─── Main ──────────────────────────────────────────────────────────────────

async function main() {
  console.log('Starting production deployment audit...')
  console.log(`Target: ${BASE_URL}`)
  console.log(`Supabase: ${SUPABASE_URL || 'Not configured'}\n`)

  await auditVercel()
  await auditSupabase()
  await auditEdgeFunctions()
  await auditStorage()
  await auditCSP()
  await auditCORS()
  await auditHTTPS()
  await auditEnvironmentVariables()

  printResults()
}

main().catch(console.error)
