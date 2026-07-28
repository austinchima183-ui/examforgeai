#!/bin/bash
# ============================================================================
# ExamForge AI — Test Runner
# ============================================================================
# Runs all tests with coverage reporting.
# Usage:
#   ./scripts/run_tests.sh              # Run all tests
#   ./scripts/run_tests.sh --security   # Run security tests only
#   ./scripts/run_tests.sh --billing    # Run billing tests only
# ============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║           ExamForge AI — Test Suite Runner                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Parse arguments
TEST_FILTER=""
case "${1:-}" in
  --security)
    TEST_FILTER="test/security/"
    echo "🔒 Running security tests only"
    ;;
  --billing)
    TEST_FILTER="test/features/billing/"
    echo "💰 Running billing tests only"
    ;;
  --core)
    TEST_FILTER="test/core/"
    echo "🧱 Running core tests only"
    ;;
  --cbt)
    TEST_FILTER="test/services/cbt/"
    echo "📝 Running CBT tests only"
    ;;
  --all|"")
    TEST_FILTER=""
    echo "🚀 Running all tests"
    ;;
  *)
    echo "Unknown option: $1"
    echo "Usage: $0 [--security|--billing|--core|--cbt|--all]"
    exit 1
    ;;
esac

echo ""

# Run tests
if [ -n "$TEST_FILTER" ]; then
  flutter test "$TEST_FILTER" --reporter=expanded
else
  flutter test --reporter=expanded
fi

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ All tests passed!"
else
  echo "❌ Some tests failed. Exit code: $EXIT_CODE"
fi

exit $EXIT_CODE
