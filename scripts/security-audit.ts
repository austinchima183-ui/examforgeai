/**
 * ExamForge AI — Security Penetration Audit
 * 
 * Automated checks for:
 * - SQL Injection
 * - XSS (Cross-Site Scripting)
 * - CSRF (Cross-Site Request Forgery)
 * - IDOR (Insecure Direct Object Reference)
 * - Broken Access Control
 * - JWT Validation
 * - File Upload Validation
 * 
 * Usage: npx tsx scripts/security-audit.ts
 */

const BASE_URL = process.env.NEXT_PUBLIC_APP_URL ?? 'http://localhost:3000'

interface SecurityResult {
  category: string
  test: string
  status: 'PASS' | 'FAIL' | 'WARN'
  details: string
}

const results: SecurityResult[] = []

async function checkResponse(
  url: string,
  options: RequestInit,
  expectation: (res: Response) => Promise<boolean>,
  testName: string,
  category: string
) {
  try {
    const res = await fetch(url, options)
    const passed = await expectation(res)
    results.push({
      category,
      test: testName,
      status: passed ? 'PASS' : 'FAIL',
      details: `HTTP ${res.status} — ${url}`,
    })
  } catch (err) {
    results.push({
      category,
      test: testName,
      status: 'FAIL',
      details: `Error: ${err instanceof Error ? err.message : 'Unknown'}`,
    })
  }
}

// ─── 1. SQL Injection ──────────────────────────────────────────────────────

async function testSQLInjection() {
  const payloads = [
    "' OR '1'='1",
    "'; DROP TABLE users; --",
    "1 UNION SELECT * FROM profiles --",
    "admin'--",
    "1; WAITFOR DELAY '0:0:5' --",
  ]

  for (const payload of payloads) {
    // Test login form
    await checkResponse(
      `${BASE_URL}/api/auth/callback`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `email=${encodeURIComponent(payload)}&password=test`,
      },
      async (res) => res.status >= 400, // Should reject malicious input
      `SQL Injection on login: ${payload.substring(0, 20)}`,
      'SQL Injection'
    )

    // Test search endpoint
    await checkResponse(
      `${BASE_URL}/api/search?q=${encodeURIComponent(payload)}`,
      { method: 'GET' },
      async (res) => {
        if (res.status === 401) return true // Auth required - good
        if (res.status === 200) {
          const text = await res.text()
          // Should not contain SQL error messages
          const sqlErrors = ['syntax error', 'SQL', 'mysql', 'postgres', 'sqlite', 'ORA-', 'unclosed quotation']
          return !sqlErrors.some(err => text.toLowerCase().includes(err.toLowerCase()))
        }
        return true
      },
      `SQL Injection on search: ${payload.substring(0, 20)}`,
      'SQL Injection'
    )
  }
}

// ─── 2. XSS ────────────────────────────────────────────────────────────────

async function testXSS() {
  const payloads = [
    '<script>alert("XSS")</script>',
    '<img src=x onerror=alert(1)>',
    'javascript:alert(1)',
    '<svg onload=alert(1)>',
    '"><script>alert(document.cookie)</script>',
  ]

  for (const payload of payloads) {
    await checkResponse(
      `${BASE_URL}/api/search?q=${encodeURIComponent(payload)}`,
      { method: 'GET' },
      async (res) => {
        if (res.status === 401) return true
        if (res.status === 200) {
          const text = await res.text()
          // Should not contain the raw script tags in the response body
          return !text.includes('<script>alert') && !text.includes('onerror=alert')
        }
        return true
      },
      `XSS on search: ${payload.substring(0, 30)}`,
      'XSS'
    )
  }

  // Test CSP header
  await checkResponse(
    BASE_URL,
    { method: 'GET' },
    async (res) => {
      const csp = res.headers.get('content-security-policy')
      if (!csp) {
        results.push({ category: 'XSS', test: 'CSP Header', status: 'FAIL', details: 'No CSP header found' })
        return false
      }
      // Should not contain unsafe-eval
      const hasUnsafeEval = csp.includes("'unsafe-eval'")
      if (hasUnsafeEval) {
        results.push({ category: 'XSS', test: 'CSP unsafe-eval', status: 'FAIL', details: 'CSP contains unsafe-eval' })
        return false
      }
      return true
    },
    'CSP Header Present and Secure',
    'XSS'
  )
}

// ─── 3. CSRF ───────────────────────────────────────────────────────────────

async function testCSRF() {
  // Test that state-changing endpoints require auth
  const endpoints = [
    { url: `${BASE_URL}/api/billing/refund`, method: 'POST' },
    { url: `${BASE_URL}/api/billing/checkout`, method: 'POST' },
  ]

  for (const endpoint of endpoints) {
    await checkResponse(
      endpoint.url,
      {
        method: endpoint.method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ test: 'csrf' }),
      },
      async (res) => res.status === 401, // Should require auth
      `CSRF protection on ${endpoint.url}`,
      'CSRF'
    )
  }

  // Check for SameSite cookies
  await checkResponse(
    BASE_URL,
    { method: 'GET' },
    async (res) => {
      const setCookie = res.headers.get('set-cookie')
      if (!setCookie) return true // No cookies being set on this request
      const hasSameSite = setCookie.toLowerCase().includes('samesite')
      if (!hasSameSite) {
        results.push({ category: 'CSRF', test: 'SameSite Cookie', status: 'WARN', details: 'Cookie missing SameSite attribute' })
      }
      return true
    },
    'SameSite Cookie Attribute',
    'CSRF'
  )
}

// ─── 4. IDOR ───────────────────────────────────────────────────────────────

async function testIDOR() {
  // Test that accessing other users' data is blocked
  const fakeIds = [
    '00000000-0000-0000-0000-000000000000',
    '1',
    'admin',
    '../etc/passwd',
  ]

  for (const id of fakeIds) {
    await checkResponse(
      `${BASE_URL}/api/analytics?school_id=${id}`,
      { method: 'GET' },
      async (res) => {
        // Should either return 401 (not authed) or 403 (not authorized) or filtered data
        if (res.status === 401 || res.status === 403) return true
        if (res.status === 200) {
          const text = await res.text()
          // Should not contain data from other schools
          return !text.includes('super_admin') || text.length < 50
        }
        return true
      },
      `IDOR on analytics with fake ID: ${id}`,
      'IDOR'
    )
  }
}

// ─── 5. Broken Access Control ──────────────────────────────────────────────

async function testBrokenAccessControl() {
  // Test that protected routes require authentication
  const protectedRoutes = [
    '/dashboard',
    '/students',
    '/teachers',
    '/schools',
    '/billing',
    '/cbt',
    '/question-bank',
    '/analytics',
    '/results',
    '/reports',
    '/marketplace',
    '/settings',
    '/profile',
    '/notifications',
  ]

  for (const route of protectedRoutes) {
    await checkResponse(
      `${BASE_URL}${route}`,
      { method: 'GET', redirect: 'manual' },
      async (res) => {
        // Should redirect to login or return 401
        if (res.status === 302 || res.status === 307) {
          const location = res.headers.get('location')
          return location?.includes('/login') ?? false
        }
        return res.status === 401
      },
      `Access control on ${route}`,
      'Broken Access Control'
    )
  }
}

// ─── 6. JWT Validation ─────────────────────────────────────────────────────

async function testJWTValidation() {
  const fakeTokens = [
    'invalid.jwt.token',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
    '',
    'null',
  ]

  for (const token of fakeTokens) {
    await checkResponse(
      `${BASE_URL}/api/analytics`,
      {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Cookie': `sb-access-token=${token}`,
        },
      },
      async (res) => res.status === 401 || res.status === 403,
      `JWT validation with fake token: ${token.substring(0, 20)}...`,
      'JWT Validation'
    )
  }
}

// ─── 7. File Upload Validation ─────────────────────────────────────────────

async function testFileUploadValidation() {
  // Test that dangerous file types are rejected
  const dangerousFiles = [
    { name: 'test.exe', type: 'application/x-msdownload' },
    { name: 'test.php', type: 'application/x-php' },
    { name: 'test.sh', type: 'application/x-sh' },
    { name: 'test.svg', type: 'image/svg+xml' }, // SVG can contain JS
  ]

  for (const file of dangerousFiles) {
    const formData = new FormData()
    formData.append('file', new Blob(['test'], { type: file.type }), file.name)

    await checkResponse(
      `${BASE_URL}/api/upload`, // Generic upload endpoint
      { method: 'POST', body: formData },
      async (res) => {
        // Should reject dangerous file types
        if (res.status === 404) return true // No upload endpoint - good
        if (res.status === 401 || res.status === 403) return true // Auth required
        if (res.status === 415 || res.status === 422) return true // Unsupported type
        return res.status !== 200 // Should not succeed
      },
      `File upload validation: ${file.name}`,
      'File Upload Validation'
    )
  }
}

// ─── 8. Security Headers ───────────────────────────────────────────────────

async function testSecurityHeaders() {
  const requiredHeaders = [
    { header: 'x-frame-options', expected: 'DENY', category: 'Clickjacking' },
    { header: 'x-content-type-options', expected: 'nosniff', category: 'MIME Sniffing' },
    { header: 'strict-transport-security', expected: 'max-age=', category: 'HSTS' },
    { header: 'referrer-policy', expected: 'strict-origin', category: 'Info Leakage' },
  ]

  for (const { header, expected, category } of requiredHeaders) {
    await checkResponse(
      BASE_URL,
      { method: 'GET' },
      async (res) => {
        const value = res.headers.get(header)
        if (!value) {
          results.push({ category: 'Security Headers', test: `${header}`, status: 'FAIL', details: `Missing header: ${header}` })
          return false
        }
        if (!value.includes(expected)) {
          results.push({ category: 'Security Headers', test: `${header}`, status: 'WARN', details: `Header ${header}: ${value} (expected: ${expected})` })
          return false
        }
        return true
      },
      `Security header: ${header}`,
      'Security Headers'
    )
  }
}

// ─── Print Results ──────────────────────────────────────────────────────────

function printResults() {
  console.log('\n' + '='.repeat(80))
  console.log('SECURITY PENETRATION AUDIT RESULTS')
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
    console.log('\n❌ SECURITY AUDIT FAILED — Fix the issues above before deploying to production.')
    process.exit(1)
  } else if (totalWarn > 0) {
    console.log('\n⚠️  SECURITY AUDIT PASSED WITH WARNINGS — Review the warnings above.')
  } else {
    console.log('\n✅ SECURITY AUDIT PASSED — All checks passed.')
  }
}

// ─── Main ──────────────────────────────────────────────────────────────────

async function main() {
  console.log('Starting security penetration audit...')
  console.log(`Target: ${BASE_URL}\n`)

  await testSQLInjection()
  await testXSS()
  await testCSRF()
  await testIDOR()
  await testBrokenAccessControl()
  await testJWTValidation()
  await testFileUploadValidation()
  await testSecurityHeaders()

  printResults()
}

main().catch(console.error)
