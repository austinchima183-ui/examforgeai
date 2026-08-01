#!/bin/bash
# Phase 4.5 Route Testing Script
BASE_URL="http://0.0.0.0:3000"
RESULTS_FILE="/home/z/my-project/download/route-test-results.txt"

echo "=== Phase 4.5 Route Testing ===" > "$RESULTS_FILE"
echo "Date: $(date -u)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

ROUTES=("/login" "/register" "/forgot-password" "/reset-password" "/verify-email" "/dashboard" "/schools" "/students" "/teachers" "/parents" "/notifications" "/profile" "/settings" "/analytics" "/billing" "/marketplace" "/question-bank" "/results" "/cbt" "/")

PASSED=0
FAILED=0

for route in "${ROUTES[@]}"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${route}")
  label=""
  if [ "$code" -ge 200 ] && [ "$code" -lt 400 ]; then
    label="PASS"
    PASSED=$((PASSED + 1))
  else
    label="FAIL"
    FAILED=$((FAILED + 1))
  fi
  echo "${route} -> ${code} [${label}]" | tee -a "$RESULTS_FILE"
  sleep 2
done

echo "" | tee -a "$RESULTS_FILE"
echo "PASSED: ${PASSED}/${#ROUTES[@]}" | tee -a "$RESULTS_FILE"
echo "FAILED: ${FAILED}/${#ROUTES[@]}" | tee -a "$RESULTS_FILE"
