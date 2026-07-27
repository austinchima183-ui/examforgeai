// ============================================================================
// ExamForge AI — k6 Load Testing Suite
// ============================================================================
// Comprehensive load testing framework for performance validation.
// Tests realistic production traffic patterns at multiple concurrency levels.
//
// Prerequisites:
//   1. Install k6: https://k6.io/docs/get-started/installation/
//   2. Set environment variables:
//      - BASE_URL: Supabase project URL
//      - ANON_KEY: Supabase anon key
//      - SERVICE_ROLE_KEY: Supabase service role key (for setup)
//
// Usage:
//   k6 run --vus 100 --duration 15m load_test.js
//   k6 run --stage "0:0,2m:100,5m:500,10m:1000,15m:0" load_test.js
//
// SCENARIOS:
//   1. Student taking CBT exam
//   2. Teacher creating exam
//   3. School admin viewing dashboard
//   4. AI question generation
//   5. Payment webhook processing
//   6. Marketplace browsing
// ============================================================================

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// ─── Custom Metrics ────────────────────────────────────────────────────────
const apiLatency = new Trend('api_latency', true);
const dbQueryLatency = new Trend('db_query_latency', true);
const aiLatency = new Trend('ai_response_latency', true);
const errorRate = new Rate('error_rate');
const cacheHitRate = new Rate('cache_hit_rate');

// ─── Configuration ─────────────────────────────────────────────────────────
const BASE_URL = __ENV.BASE_URL || 'https://your-project.supabase.co';
const ANON_KEY = __ENV.ANON_KEY || '';
const SERVICE_ROLE_KEY = __ENV.SERVICE_ROLE_KEY || '';

const headers = {
  'apikey': ANON_KEY,
  'Content-Type': 'application/json',
  'Prefer': 'return=representation',
};

// ─── Test Scenarios ────────────────────────────────────────────────────────
export const options = {
  // Stage-based ramping for comprehensive load testing
  stages: [
    { duration: '2m', target: 100 },   // Ramp to 100 users
    { duration: '5m', target: 100 },   // Sustain 100 users
    { duration: '2m', target: 500 },   // Ramp to 500 users
    { duration: '5m', target: 500 },   // Sustain 500 users
    { duration: '2m', target: 1000 },  // Ramp to 1000 users
    { duration: '5m', target: 1000 },  // Sustain 1000 users
    { duration: '2m', target: 5000 },  // Ramp to 5000 users
    { duration: '5m', target: 5000 },  // Sustain 5000 users
    { duration: '3m', target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(50)<300', 'p(90)<800', 'p(95)<1500', 'p(99)<3000'],
    error_rate: ['rate<0.05'],  // < 5% error rate
    api_latency: ['p(95)<1000'],
    db_query_latency: ['p(95)<500'],
    ai_response_latency: ['p(95)<10000'],
  },
};

// ─── Test Data ─────────────────────────────────────────────────────────────
const testSchoolId = '00000000-0000-0000-0000-000000000001';
const testExamId = '00000000-0000-0000-0000-000000000002';

// ─── Helper Functions ──────────────────────────────────────────────────────
function measureApiCall(url, params, metric) {
  const start = Date.now();
  const response = http.get(url, params);
  const duration = Date.now() - start;
  
  if (metric) metric.add(duration);
  
  const success = check(response, {
    'status is 2xx': (r) => r.status >= 200 && r.status < 300,
  });
  
  errorRate.add(!success);
  return response;
}

// ─── Scenario 1: Student CBT Exam Flow ─────────────────────────────────────
function studentCbtFlow() {
  group('Student: Load Exam', () => {
    // Load exam details
    const examUrl = `${BASE_URL}/rest/v1/exams?id=eq.${testExamId}&select=id,title,settings,duration_minutes`;
    const res = measureApiCall(examUrl, { headers }, apiLatency);
    
    sleep(1); // Simulate reading exam instructions
  });

  group('Student: Load Questions', () => {
    // Load exam questions (CRITICAL: This should use pagination)
    const questionsUrl = `${BASE_URL}/rest/v1/questions?exam_id=eq.${testExamId}&select=id,content_json,question_type,difficulty&limit=50`;
    const res = measureApiCall(questionsUrl, { headers }, dbQueryLatency);
    
    sleep(0.5); // Simulate reading questions
  });

  group('Student: Submit Answers', () => {
    // Submit an answer
    const answerPayload = JSON.stringify({
      exam_id: testExamId,
      question_id: '00000000-0000-0000-0000-000000000003',
      student_answer: 'B',
    });
    
    const answerUrl = `${BASE_URL}/rest/v1/student_answers`;
    const res = http.post(answerUrl, answerPayload, { headers });
    
    check(res, { 'answer submitted': (r) => r.status === 201 });
    errorRate.add(res.status !== 201);
    
    sleep(2); // Simulate time between answers
  });
}

// ─── Scenario 2: Teacher Creating Exam ─────────────────────────────────────
function teacherCreateExamFlow() {
  group('Teacher: Browse Question Bank', () => {
    // List questions with pagination (optimized path)
    const url = `${BASE_URL}/rest/v1/questions?school_id=eq.${testSchoolId}&select=id,title,difficulty,subject_id&limit=20&offset=0`;
    measureApiCall(url, { headers }, dbQueryLatency);
    
    sleep(2);
  });

  group('Teacher: AI Generate Questions', () => {
    // Trigger AI question generation (high-latency operation)
    const genPayload = JSON.stringify({
      subject: 'Mathematics',
      topic: 'Algebra',
      difficulty: 'medium',
      question_type: 'multiple_choice',
      count: 5,
    });
    
    const genUrl = `${BASE_URL}/rest/v1/rpc/generate_questions`;
    const start = Date.now();
    const res = http.post(genUrl, genPayload, { headers });
    const duration = Date.now() - start;
    
    aiLatency.add(duration);
    check(res, { 'AI generation succeeded': (r) => r.status === 200 });
    errorRate.add(res.status !== 200);
    
    sleep(5); // Simulate reviewing generated questions
  });
}

// ─── Scenario 3: School Admin Dashboard ────────────────────────────────────
function adminDashboardFlow() {
  group('Admin: Load Dashboard', () => {
    // Dashboard loads multiple counts (current pattern: 6 parallel select('id'))
    const endpoints = [
      `${BASE_URL}/rest/v1/student_profiles?school_id=eq.${testSchoolId}&is_active=eq.true&select=id`,
      `${BASE_URL}/rest/v1/teacher_profiles?school_id=eq.${testSchoolId}&is_active=eq.true&select=id`,
      `${BASE_URL}/rest/v1/classes?school_id=eq.${testSchoolId}&is_active=eq.true&select=id`,
      `${BASE_URL}/rest/v1/exams?school_id=eq.${testSchoolId}&select=id`,
    ];
    
    // Simulate parallel fetches
    const start = Date.now();
    const responses = http.batch(
      endpoints.map(url => ['GET', url, null, { headers }])
    );
    const duration = Date.now() - start;
    
    apiLatency.add(duration);
    responses.forEach(res => {
      check(res, { 'dashboard data loaded': (r) => r.status === 200 });
      errorRate.add(res.status !== 200);
    });
    
    sleep(10); // Dashboard viewed for ~10 seconds
  });
}

// ─── Scenario 4: Marketplace Browsing ──────────────────────────────────────
function marketplaceFlow() {
  group('User: Browse Marketplace', () => {
    const url = `${BASE_URL}/rest/v1/marketplace_products?status=eq.published&select=id,title,price,rating&limit=20&offset=0&order=rating.desc`;
    measureApiCall(url, { headers }, apiLatency);
    
    sleep(3);
  });

  group('User: View Product Details', () => {
    const url = `${BASE_URL}/rest/v1/marketplace_products?id=eq.00000000-0000-0000-0000-000000000004&select=*`;
    measureApiCall(url, { headers }, apiLatency);
    
    sleep(2);
  });
}

// ─── Scenario 5: Health Check ──────────────────────────────────────────────
function healthCheckFlow() {
  group('Monitor: Health Check', () => {
    const url = `${BASE_URL}/functions/v1/health-check`;
    const res = http.get(url, { headers: { 'apikey': ANON_KEY } });
    
    check(res, { 'health check ok': (r) => r.status === 200 });
    sleep(30); // Health checks every 30 seconds
  });
}

// ─── Main Test Function ────────────────────────────────────────────────────
export default function () {
  // Distribute scenarios across VUs
  const scenario = __VU % 5;
  
  switch (scenario) {
    case 0:
      studentCbtFlow();
      break;
    case 1:
      teacherCreateExamFlow();
      break;
    case 2:
      adminDashboardFlow();
      break;
    case 3:
      marketplaceFlow();
      break;
    case 4:
      healthCheckFlow();
      break;
  }
  
  sleep(Math.random() * 3 + 1); // Random think time 1-4 seconds
}

// ─── Setup Function ────────────────────────────────────────────────────────
export function setup() {
  console.log('ExamForge AI Load Test Starting...');
  console.log(`Target: ${BASE_URL}`);
  console.log('Scenario distribution: 20% CBT, 20% Teacher, 20% Admin, 20% Marketplace, 20% Health');
  return { startTime: Date.now() };
}

// ─── Teardown Function ─────────────────────────────────────────────────────
export function teardown(data) {
  const duration = (Date.now() - data.startTime) / 1000;
  console.log(`Load Test Complete. Duration: ${duration.toFixed(1)}s`);
}
