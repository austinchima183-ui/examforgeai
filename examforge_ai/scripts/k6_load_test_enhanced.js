// ============================================================================
// ExamForge AI — Enhanced k6 Load Testing Suite
// ============================================================================
// Comprehensive load testing framework with:
//   1. Realistic traffic distribution based on Nigerian school patterns
//   2. Multi-scenario testing (CBT, AI, Dashboard, Billing, Marketplace)
//   3. Detailed metrics collection (latency percentiles, error rates)
//   4. Staged ramp-up for scalability validation
//   5. Before/after comparison support
//
// USAGE:
//   k6 run --env BASE_URL=https://your-project.supabase.co \
//          --env ANON_KEY=your-anon-key \
//          --env SERVICE_ROLE_KEY=your-service-role-key \
//          scripts/k6_load_test_enhanced.js
//
// For scalability validation at specific tiers:
//   k6 run --env TIER=10 ...    (10 schools)
//   k6 run --env TIER=100 ...   (100 schools)
//   k6 run --env TIER=1000 ...  (1,000 schools)
// ============================================================================

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter, Gauge } from 'k6/metrics';

// ─── Custom Metrics ────────────────────────────────────────────────────────

// API latency by endpoint category
const apiLatency = new Trend('api_latency', true);
const dbQueryLatency = new Trend('db_query_latency', true);
const aiResponseLatency = new Trend('ai_response_latency', true);
const cbtExamLatency = new Trend('cbt_exam_latency', true);
const dashboardLatency = new Trend('dashboard_latency', true);
const marketplaceLatency = new Trend('marketplace_latency', true);
const billingLatency = new Trend('billing_latency', true);

// Error tracking
const errorRate = new Rate('error_rate');
const authErrorRate = new Rate('auth_error_rate');
const dbErrorRate = new Rate('db_error_rate');
const aiErrorRate = new Rate('ai_error_rate');

// Cache metrics
const cacheHitRate = new Rate('cache_hit_rate');

// Resource metrics
const activeConnections = new Gauge('active_connections');
const requestThroughput = new Counter('request_throughput');

// ─── Configuration ─────────────────────────────────────────────────────────

const BASE_URL = __ENV.BASE_URL || 'https://your-project.supabase.co';
const ANON_KEY = __ENV.ANON_KEY || '';
const SERVICE_ROLE_KEY = __ENV.SERVICE_ROLE_KEY || '';
const TIER = parseInt(__ENV.TIER || '100');

const headers = {
  'apikey': ANON_KEY,
  'Content-Type': 'application/json',
  'Prefer': 'return=representation',
};

// ─── Scale-Based Configuration ─────────────────────────────────────────────
// Tier configs adjust VU count and thresholds based on target school count.

const tierConfigs = {
  10: {
    vus: 50,
    duration: '5m',
    stages: [
      { duration: '1m', target: 20 },
      { duration: '2m', target: 50 },
      { duration: '1m', target: 20 },
      { duration: '1m', target: 0 },
    ],
    thresholds: {
      http_req_duration: ['p(50)<200', 'p(90)<500', 'p(95)<1000', 'p(99)<2000'],
      error_rate: ['rate<0.02'],
      api_latency: ['p(95)<500'],
      db_query_latency: ['p(95)<300'],
      ai_response_latency: ['p(95)<8000'],
      cbt_exam_latency: ['p(95)<500'],
      dashboard_latency: ['p(95)<1000'],
    },
  },
  100: {
    vus: 200,
    duration: '10m',
    stages: [
      { duration: '2m', target: 100 },
      { duration: '3m', target: 200 },
      { duration: '3m', target: 200 },
      { duration: '2m', target: 0 },
    ],
    thresholds: {
      http_req_duration: ['p(50)<300', 'p(90)<800', 'p(95)<1500', 'p(99)<3000'],
      error_rate: ['rate<0.03'],
      api_latency: ['p(95)<1000'],
      db_query_latency: ['p(95)<500'],
      ai_response_latency: ['p(95)<10000'],
      cbt_exam_latency: ['p(95)<800'],
      dashboard_latency: ['p(95)<1500'],
    },
  },
  1000: {
    vus: 1000,
    duration: '15m',
    stages: [
      { duration: '2m', target: 200 },
      { duration: '3m', target: 500 },
      { duration: '3m', target: 1000 },
      { duration: '5m', target: 1000 },
      { duration: '2m', target: 0 },
    ],
    thresholds: {
      http_req_duration: ['p(50)<500', 'p(90)<1500', 'p(95)<3000', 'p(99)<5000'],
      error_rate: ['rate<0.05'],
      api_latency: ['p(95)<2000'],
      db_query_latency: ['p(95)<1000'],
      ai_response_latency: ['p(95)<15000'],
      cbt_exam_latency: ['p(95)<1500'],
      dashboard_latency: ['p(95)<3000'],
    },
  },
};

const config = tierConfigs[TIER] || tierConfigs[100];

export const options = {
  stages: config.stages,
  thresholds: config.thresholds,
};

// ─── Test Data ─────────────────────────────────────────────────────────────

const testSchoolId = '00000000-0000-0000-0000-000000000001';
const testExamId = '00000000-0000-0000-0000-000000000002';
const testStudentId = '00000000-0000-0000-0000-000000000003';
const testTeacherId = '00000000-0000-0000-0000-000000000004';
const testQuestionId = '00000000-0000-0000-0000-000000000005';

// ─── Helper Functions ──────────────────────────────────────────────────────

function measureAndRecord(url, params, latencyMetric, errorMetric) {
  const start = Date.now();
  const response = http.get(url, params);
  const duration = Date.now() - start;

  if (latencyMetric) latencyMetric.add(duration);
  if (errorMetric) errorMetric.add(response.status >= 400);

  requestThroughput.add(1);

  check(response, {
    'status is 2xx': (r) => r.status >= 200 && r.status < 300,
  });

  errorRate.add(response.status >= 400);
  return response;
}

function measurePost(url, payload, params, latencyMetric, errorMetric) {
  const start = Date.now();
  const response = http.post(url, JSON.stringify(payload), params);
  const duration = Date.now() - start;

  if (latencyMetric) latencyMetric.add(duration);
  if (errorMetric) errorMetric.add(response.status >= 400);

  requestThroughput.add(1);

  check(response, {
    'status is 2xx or 201': (r) => r.status >= 200 && r.status < 300,
  });

  errorRate.add(response.status >= 400);
  return response;
}

// ─── Scenario 1: Student CBT Exam Flow ─────────────────────────────────────
// Most critical: real-time exam taking with auto-save.

function studentCbtFlow() {
  // 1a. Load exam details (paginated - optimized)
  group('Student: Load Exam Details', () => {
    const url = `${BASE_URL}/rest/v1/exams?id=eq.${testExamId}&select=id,title,settings,duration_minutes,status`;
    measureAndRecord(url, { headers }, cbtExamLatency, dbErrorRate);
    sleep(1);
  });

  // 1b. Load exam questions (paginated with limit - optimized)
  group('Student: Load Questions (Paginated)', () => {
    const url = `${BASE_URL}/rest/v1/questions?exam_id=eq.${testExamId}&select=id,content_json,question_type,difficulty,marks&limit=20&offset=0`;
    measureAndRecord(url, { headers }, cbtExamLatency, dbErrorRate);
    sleep(0.5);
  });

  // 1c. Load next page of questions (simulating scroll)
  group('Student: Load More Questions', () => {
    const url = `${BASE_URL}/rest/v1/questions?exam_id=eq.${testExamId}&select=id,content_json,question_type,difficulty&limit=20&offset=20`;
    measureAndRecord(url, { headers }, cbtExamLatency, dbErrorRate);
    sleep(0.3);
  });

  // 1d. Submit an answer (auto-save pattern)
  group('Student: Submit Answer', () => {
    const payload = {
      exam_id: testExamId,
      question_id: testQuestionId,
      student_answer: 'B',
      answered_at: new Date().toISOString(),
    };

    const url = `${BASE_URL}/rest/v1/student_answers`;
    measurePost(url, payload, { headers }, cbtExamLatency, dbErrorRate);
    sleep(2);
  });

  // 1e. Check exam attempt status
  group('Student: Check Attempt Status', () => {
    const url = `${BASE_URL}/rest/v1/exam_attempts?exam_id=eq.${testExamId}&student_id=eq.${testStudentId}&select=id,status,score_percentage&limit=1`;
    measureAndRecord(url, { headers }, cbtExamLatency, dbErrorRate);
    sleep(1);
  });
}

// ─── Scenario 2: Teacher Creating Exam + AI Generation ────────────────────

function teacherCreateExamFlow() {
  // 2a. Browse question bank (paginated - optimized)
  group('Teacher: Browse Question Bank (Paginated)', () => {
    const url = `${BASE_URL}/rest/v1/questions?school_id=eq.${testSchoolId}&select=id,content_json,question_type,difficulty,subject_id,status&limit=20&offset=0&order=created_at.desc`;
    measureAndRecord(url, { headers }, dbQueryLatency, dbErrorRate);
    sleep(2);
  });

  // 2b. Search questions (full-text search - optimized)
  group('Teacher: Search Questions', () => {
    const url = `${BASE_URL}/rest/v1/questions?school_id=eq.${testSchoolId}&content_json.ilike.*algebra*&select=id,content_json,question_type,difficulty&limit=10`;
    measureAndRecord(url, { headers }, dbQueryLatency, dbErrorRate);
    sleep(1);
  });

  // 2c. AI question generation (high-latency operation)
  group('Teacher: AI Generate Questions', () => {
    const payload = {
      subject: 'Mathematics',
      topic: 'Algebra',
      difficulty: 'medium',
      question_type: 'multiple_choice',
      count: 5,
    };

    const url = `${BASE_URL}/rest/v1/rpc/generate_questions`;
    measurePost(url, payload, { headers }, aiResponseLatency, aiErrorRate);
    sleep(5);
  });
}

// ─── Scenario 3: School Admin Dashboard (Critical for RLS) ────────────────

function adminDashboardFlow() {
  // 3a. Load dashboard (using materialized view - optimized)
  group('Admin: Load Dashboard (Optimized)', () => {
    // Use materialized view instead of 4 parallel count queries
    const url = `${BASE_URL}/rest/v1/mv_school_dashboard_summary?school_id=eq.${testSchoolId}&select=*`;
    measureAndRecord(url, { headers }, dashboardLatency, dbErrorRate);
    sleep(2);
  });

  // 3b. Load recent transactions (paginated - optimized)
  group('Admin: Recent Transactions (Paginated)', () => {
    const url = `${BASE_URL}/rest/v1/transactions?school_id=eq.${testSchoolId}&select=id,amount,currency,status,created_at&limit=20&offset=0&order=created_at.desc`;
    measureAndRecord(url, { headers }, dashboardLatency, dbErrorRate);
    sleep(2);
  });

  // 3c. Load exam results summary (materialized view - optimized)
  group('Admin: Exam Results Summary', () => {
    const url = `${BASE_URL}/rest/v1/mv_exam_results_summary?school_id=eq.${testSchoolId}&select=exam_id,exam_title,total_attempts,completed_attempts,avg_score&limit=20`;
    measureAndRecord(url, { headers }, dashboardLatency, dbErrorRate);
    sleep(3);
  });
}

// ─── Scenario 4: Marketplace Browsing ──────────────────────────────────────

function marketplaceFlow() {
  // 4a. Browse products (paginated - optimized)
  group('User: Browse Marketplace (Paginated)', () => {
    const url = `${BASE_URL}/rest/v1/marketplace_products?status=eq.published&select=id,title,price,currency,rating,download_count&limit=20&offset=0&order=rating.desc`;
    measureAndRecord(url, { headers }, marketplaceLatency, dbErrorRate);
    sleep(3);
  });

  // 4b. View product details (selective columns)
  group('User: View Product Details', () => {
    const url = `${BASE_URL}/rest/v1/marketplace_products?id=eq.00000000-0000-0000-0000-000000000004&select=id,title,description,price,rating,seller_id`;
    measureAndRecord(url, { headers }, marketplaceLatency, dbErrorRate);
    sleep(2);
  });

  // 4c. Search marketplace
  group('User: Search Marketplace', () => {
    const url = `${BASE_URL}/rest/v1/marketplace_products?status=eq.published&title.ilike.*math*&select=id,title,price,rating&limit=10`;
    measureAndRecord(url, { headers }, marketplaceLatency, dbErrorRate);
    sleep(2);
  });
}

// ─── Scenario 5: Billing Flow ──────────────────────────────────────────────

function billingFlow() {
  // 5a. Load subscription plans (cached - optimized)
  group('User: View Plans', () => {
    const url = `${BASE_URL}/rest/v1/subscription_plans?is_active=eq.true&select=id,name,price,currency,interval,features&limit=10`;
    measureAndRecord(url, { headers }, billingLatency, dbErrorRate);
    sleep(2);
  });

  // 5b. Load billing history (paginated)
  group('User: Billing History', () => {
    const url = `${BASE_URL}/rest/v1/transactions?user_id=eq.${testStudentId}&select=id,amount,currency,status,created_at&limit=20&offset=0&order=created_at.desc`;
    measureAndRecord(url, { headers }, billingLatency, dbErrorRate);
    sleep(2);
  });

  // 5c. Check AI credits balance
  group('User: AI Credits Balance', () => {
    const url = `${BASE_URL}/rest/v1/ai_credits?user_id=eq.${testStudentId}&select=balance,total_used,last_used_at&limit=1`;
    measureAndRecord(url, { headers }, billingLatency, dbErrorRate);
    sleep(1);
  });
}

// ─── Scenario 6: CCMS Content Management ───────────────────────────────────

function ccmsFlow() {
  // 6a. Load curricula list (paginated)
  group('Admin: Load Curricula', () => {
    const url = `${BASE_URL}/rest/v1/curricula?is_active=eq.true&select=id,name,country,educational_level&limit=20`;
    measureAndRecord(url, { headers }, dbQueryLatency, dbErrorRate);
    sleep(2);
  });

  // 6b. Load subjects (paginated)
  group('Admin: Load Subjects', () => {
    const url = `${BASE_URL}/rest/v1/subjects?is_active=eq.true&select=id,name,code,curriculum_id&limit=30`;
    measureAndRecord(url, { headers }, dbQueryLatency, dbErrorRate);
    sleep(1);
  });

  // 6c. Load content items (paginated - optimized)
  group('Admin: Load Content Items', () => {
    const url = `${BASE_URL}/rest/v1/content_items?school_id=eq.${testSchoolId}&select=id,title,content_type,status,created_at&limit=20&offset=0&order=created_at.desc`;
    measureAndRecord(url, { headers }, dbQueryLatency, dbErrorRate);
    sleep(2);
  });
}

// ─── Scenario 7: Health Check & Infrastructure ────────────────────────────

function healthCheckFlow() {
  group('Monitor: Health Check', () => {
    const url = `${BASE_URL}/functions/v1/health-check`;
    const res = http.get(url, { headers: { 'apikey': ANON_KEY } });
    check(res, { 'health check ok': (r) => r.status === 200 });
    sleep(30);
  });
}

// ─── Main Test Function ────────────────────────────────────────────────────

export default function () {
  // Distribute scenarios across VUs based on realistic traffic patterns
  // Nigerian school pattern: 60% students, 20% teachers, 10% admins, 5% marketplace, 5% other
  const scenario = __VU % 20;

  if (scenario < 12) {
    // 60% - Student CBT flow
    studentCbtFlow();
  } else if (scenario < 16) {
    // 20% - Teacher flow
    teacherCreateExamFlow();
  } else if (scenario < 18) {
    // 10% - Admin dashboard
    adminDashboardFlow();
  } else if (scenario === 18) {
    // 5% - Marketplace
    marketplaceFlow();
  } else {
    // 5% - Billing
    billingFlow();
  }

  sleep(Math.random() * 3 + 1); // Random think time 1-4 seconds
}

// ─── Setup Function ────────────────────────────────────────────────────────

export function setup() {
  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║  ExamForge AI — Enhanced Load Testing Suite          ║');
  console.log('╚══════════════════════════════════════════════════════╝');
  console.log(`Target: ${BASE_URL}`);
  console.log(`Tier: ${TIER} schools (${config.vus} VUs)`);
  console.log('Traffic: 60% Student CBT, 20% Teacher, 10% Admin, 5% Marketplace, 5% Billing');
  console.log('Optimizations: Paginated queries, Materialized views, JWT RLS claims');
  return { startTime: Date.now(), tier: TIER };
}

// ─── Teardown Function ─────────────────────────────────────────────────────

export function teardown(data) {
  const duration = (Date.now() - data.startTime) / 1000;
  console.log(`\nLoad Test Complete.`);
  console.log(`Tier: ${data.tier} schools`);
  console.log(`Duration: ${duration.toFixed(1)}s`);
  console.log('\nCollect metrics from k6 output for before/after comparison.');
}
