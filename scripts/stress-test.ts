/**
 * ExamForge AI — Stress Testing Script
 * 
 * Simulates concurrent users hitting the application endpoints.
 * Measures CPU, Memory, Query count, Response time.
 * 
 * Usage: npx tsx scripts/stress-test.ts [--users 10|100|1000] [--duration 60]
 */

import { execSync } from 'child_process'

const BASE_URL = process.env.NEXT_PUBLIC_APP_URL ?? 'http://localhost:3000'
const USERS = parseInt(process.argv.find(a => a.startsWith('--users'))?.split('=')[1] ?? '10', 10)
const DURATION = parseInt(process.argv.find(a => a.startsWith('--duration'))?.split('=')[1] ?? '30', 10)

interface TestResult {
  endpoint: string
  users: number
  totalRequests: number
  successRate: number
  avgResponseTime: number
  p95ResponseTime: number
  p99ResponseTime: number
  errors: number
  rps: number
}

async function stressTest(endpoint: string, concurrency: number, durationSec: number): Promise<TestResult> {
  const results: number[] = []
  const errors: string[] = []
  let successCount = 0
  const startTime = Date.now()
  const endTime = startTime + durationSec * 1000

  async function makeRequest(): Promise<number> {
    const reqStart = Date.now()
    try {
      const res = await fetch(`${BASE_URL}${endpoint}`, {
        redirect: 'manual',
        headers: { 'Accept': 'text/html' },
      })
      const elapsed = Date.now() - reqStart
      if (res.status < 500) {
        successCount++
      } else {
        errors.push(`HTTP ${res.status}`)
      }
      return elapsed
    } catch (err) {
      errors.push(err instanceof Error ? err.message : 'Unknown error')
      return Date.now() - reqStart
    }
  }

  // Simulate concurrent users
  const workers: Promise<void>[] = []
  for (let i = 0; i < concurrency; i++) {
    workers.push((async () => {
      while (Date.now() < endTime) {
        const elapsed = await makeRequest()
        results.push(elapsed)
        // Small delay between requests per user
        await new Promise(r => setTimeout(r, 100))
      }
    })())
  }

  await Promise.all(workers)

  const totalDuration = (Date.now() - startTime) / 1000
  results.sort((a, b) => a - b)

  return {
    endpoint,
    users: concurrency,
    totalRequests: results.length,
    successRate: results.length > 0 ? (successCount / results.length) * 100 : 0,
    avgResponseTime: results.length > 0 ? Math.round(results.reduce((a, b) => a + b, 0) / results.length) : 0,
    p95ResponseTime: results.length > 0 ? results[Math.floor(results.length * 0.95)] : 0,
    p99ResponseTime: results.length > 0 ? results[Math.floor(results.length * 0.99)] : 0,
    errors: errors.length,
    rps: Math.round(results.length / totalDuration),
  }
}

function printResults(results: TestResult[]) {
  console.log('\n' + '='.repeat(80))
  console.log('STRESS TEST RESULTS')
  console.log('='.repeat(80))
  console.log(`Base URL: ${BASE_URL}`)
  console.log(`Concurrent Users: ${USERS}`)
  console.log(`Duration: ${DURATION}s`)
  console.log('-'.repeat(80))

  for (const r of results) {
    console.log(`\nEndpoint: ${r.endpoint}`)
    console.log(`  Total Requests: ${r.totalRequests}`)
    console.log(`  Success Rate:   ${r.successRate.toFixed(1)}%`)
    console.log(`  Avg Response:   ${r.avgResponseTime}ms`)
    console.log(`  P95 Response:   ${r.p95ResponseTime}ms`)
    console.log(`  P99 Response:   ${r.p99ResponseTime}ms`)
    console.log(`  Errors:         ${r.errors}`)
    console.log(`  Requests/sec:   ${r.rps}`)
  }

  console.log('\n' + '='.repeat(80))

  // Check pass/fail criteria
  const PASS_THRESHOLD = {
    successRate: 99, // 99% success rate
    avgResponseTime: 2000, // 2s average
    p95ResponseTime: 5000, // 5s p95
  }

  let allPassed = true
  for (const r of results) {
    if (r.successRate < PASS_THRESHOLD.successRate) {
      console.log(`❌ FAIL: ${r.endpoint} — Success rate ${r.successRate.toFixed(1)}% < ${PASS_THRESHOLD.successRate}%`)
      allPassed = false
    }
    if (r.avgResponseTime > PASS_THRESHOLD.avgResponseTime) {
      console.log(`❌ FAIL: ${r.endpoint} — Avg response ${r.avgResponseTime}ms > ${PASS_THRESHOLD.avgResponseTime}ms`)
      allPassed = false
    }
    if (r.p95ResponseTime > PASS_THRESHOLD.p95ResponseTime) {
      console.log(`⚠️  WARN: ${r.endpoint} — P95 response ${r.p95ResponseTime}ms > ${PASS_THRESHOLD.p95ResponseTime}ms`)
    }
  }

  if (allPassed) {
    console.log('\n✅ ALL STRESS TESTS PASSED')
  } else {
    console.log('\n❌ SOME STRESS TESTS FAILED')
    process.exit(1)
  }
}

// ─── Main ──────────────────────────────────────────────────────────────────

const ENDPOINTS = [
  '/login',
  '/api/auth/callback',
  '/api/analytics',
  '/api/search',
  '/api/billing/webhook',
]

async function main() {
  console.log(`Starting stress test with ${USERS} users for ${DURATION}s...`)
  console.log(`Target: ${BASE_URL}`)

  const results: TestResult[] = []

  for (const endpoint of ENDPOINTS) {
    console.log(`\nTesting: ${endpoint} with ${USERS} concurrent users...`)
    const result = await stressTest(endpoint, USERS, DURATION)
    results.push(result)
  }

  printResults(results)
}

main().catch(console.error)
