#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
# ExamForge AI — Test Runner Script
#
# Runs all test types: unit, widget, integration
# Generates coverage report and test result summary
# ═══════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RESULTS_DIR="${PROJECT_DIR}/test_results"
COVERAGE_DIR="${PROJECT_DIR}/coverage"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

# ─── Helper Functions ──────────────────────────────────────────────────

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_separator() {
    echo "═══════════════════════════════════════════════════════════════"
}

setup_results_dir() {
    rm -rf "${RESULTS_DIR}"
    mkdir -p "${RESULTS_DIR}"
    rm -rf "${COVERAGE_DIR}"
    mkdir -p "${COVERAGE_DIR}"
}

check_flutter() {
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    log_info "Flutter version: $(flutter --version | head -1)"
}

parse_test_output() {
    local output_file="$1"
    local test_type="$2"

    if [ ! -f "${output_file}" ]; then
        log_error "No output file found for ${test_type}"
        return 1
    fi

    # Parse test results from flutter test output
    local passed failed skipped total
    passed=$(grep -oP '\d+(?= passed)' "${output_file}" 2>/dev/null || echo "0")
    failed=$(grep -oP '\d+(?= failed)' "${output_file}" 2>/dev/null || echo "0")
    skipped=$(grep -oP '\d+(?= skipped)' "${output_file}" 2>/dev/null || echo "0")
    total=$((passed + failed + skipped))

    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    TOTAL_SKIPPED=$((TOTAL_SKIPPED + skipped))
    TOTAL_TESTS=$((TOTAL_TESTS + total))

    echo "  ${test_type}: ${total} total | ${GREEN}${passed} passed${NC} | ${RED}${failed} failed${NC} | ${YELLOW}${skipped} skipped${NC}"
}

# ─── Unit Tests ────────────────────────────────────────────────────────

run_unit_tests() {
    print_separator
    log_info "Running Unit Tests..."
    print_separator

    local output_file="${RESULTS_DIR}/unit_test_output.txt"

    if flutter test test/ \
        --reporter=expanded \
        --coverage \
        --coverage-path="${COVERAGE_DIR}/lcov_unit.info" \
        --exclude-tags=integration \
        2>&1 | tee "${output_file}"; then
        log_success "Unit tests completed"
    else
        log_warn "Some unit tests may have failed"
    fi

    parse_test_output "${output_file}" "Unit Tests"
}

# ─── Widget Tests ──────────────────────────────────────────────────────

run_widget_tests() {
    print_separator
    log_info "Running Widget Tests..."
    print_separator

    local output_file="${RESULTS_DIR}/widget_test_output.txt"

    if flutter test test/ccms/presentation/widgets/ \
        --reporter=expanded \
        --coverage \
        --coverage-path="${COVERAGE_DIR}/lcov_widget.info" \
        2>&1 | tee "${output_file}"; then
        log_success "Widget tests completed"
    else
        log_warn "Some widget tests may have failed"
    fi

    parse_test_output "${output_file}" "Widget Tests"
}

# ─── Integration Tests ─────────────────────────────────────────────────

run_integration_tests() {
    print_separator
    log_info "Running Integration Tests..."
    print_separator

    local output_file="${RESULTS_DIR}/integration_test_output.txt"

    if [ -d "test/ccms/integration" ]; then
        if flutter test test/ccms/integration/ \
            --reporter=expanded \
            --coverage \
            --coverage-path="${COVERAGE_DIR}/lcov_integration.info" \
            --tags=integration \
            2>&1 | tee "${output_file}"; then
            log_success "Integration tests completed"
        else
            log_warn "Some integration tests may have failed"
        fi

        parse_test_output "${output_file}" "Integration Tests"
    else
        log_warn "No integration test directory found, skipping"
    fi
}

# ─── CCMS Domain Tests ────────────────────────────────────────────────

run_ccms_domain_tests() {
    print_separator
    log_info "Running CCMS Domain Layer Tests..."
    print_separator

    local output_file="${RESULTS_DIR}/ccms_domain_test_output.txt"

    if [ -d "test/ccms/domain" ]; then
        if flutter test test/ccms/domain/ \
            --reporter=expanded \
            --coverage \
            --coverage-path="${COVERAGE_DIR}/lcov_ccms_domain.info" \
            2>&1 | tee "${output_file}"; then
            log_success "CCMS domain tests completed"
        else
            log_warn "Some CCMS domain tests may have failed"
        fi

        parse_test_output "${output_file}" "CCMS Domain Tests"
    else
        log_warn "No CCMS domain test directory found, skipping"
    fi
}

# ─── CCMS Data Tests ──────────────────────────────────────────────────

run_ccms_data_tests() {
    print_separator
    log_info "Running CCMS Data Layer Tests..."
    print_separator

    local output_file="${RESULTS_DIR}/ccms_data_test_output.txt"

    if [ -d "test/ccms/data" ]; then
        if flutter test test/ccms/data/ \
            --reporter=expanded \
            --coverage \
            --coverage-path="${COVERAGE_DIR}/lcov_ccms_data.info" \
            2>&1 | tee "${output_file}"; then
            log_success "CCMS data tests completed"
        else
            log_warn "Some CCMS data tests may have failed"
        fi

        parse_test_output "${output_file}" "CCMS Data Tests"
    else
        log_warn "No CCMS data test directory found, skipping"
    fi
}

# ─── CCMS Security Tests ──────────────────────────────────────────────

run_ccms_security_tests() {
    print_separator
    log_info "Running CCMS Security Tests..."
    print_separator

    local output_file="${RESULTS_DIR}/ccms_security_test_output.txt"

    if [ -d "test/ccms/security" ]; then
        if flutter test test/ccms/security/ \
            --reporter=expanded \
            --coverage \
            --coverage-path="${COVERAGE_DIR}/lcov_ccms_security.info" \
            2>&1 | tee "${output_file}"; then
            log_success "CCMS security tests completed"
        else
            log_warn "Some CCMS security tests may have failed"
        fi

        parse_test_output "${output_file}" "CCMS Security Tests"
    else
        log_warn "No CCMS security test directory found, skipping"
    fi
}

# ─── Coverage Report ──────────────────────────────────────────────────

generate_coverage_report() {
    print_separator
    log_info "Generating Coverage Report..."
    print_separator

    # Merge all coverage files
    local merged_lcov="${COVERAGE_DIR}/lcov.info"

    if [ -f "${COVERAGE_DIR}/lcov_unit.info" ]; then
        cp "${COVERAGE_DIR}/lcov_unit.info" "${merged_lcov}"
        log_info "Merged unit test coverage"
    fi

    for lcov_file in "${COVERAGE_DIR}"/lcov_*.info; do
        if [ -f "$lcov_file" ] && [ "$lcov_file" != "${COVERAGE_DIR}/lcov_unit.info" ] && [ "$lcov_file" != "${merged_lcov}" ]; then
            # Append coverage data
            cat "$lcov_file" >> "${merged_lcov}"
            log_info "Merged $(basename "$lcov_file")"
        fi
    done

    # Generate HTML report if lcov is available
    if command -v genhtml &> /dev/null && [ -f "${merged_lcov}" ]; then
        genhtml "${merged_lcov}" -o "${COVERAGE_DIR}/html" \
            --title "ExamForge AI Test Coverage" \
            --legend \
            --show-details \
            2>/dev/null || true
        log_success "HTML coverage report generated at ${COVERAGE_DIR}/html/index.html"
    else
        log_warn "genhtml not available. Install lcov for HTML reports."
        log_info "LCOV data available at ${merged_lcov}"
    fi

    # Calculate coverage percentage
    if [ -f "${merged_lcov}" ]; then
        local total_lines covered_lines percentage
        total_lines=$(grep -c "^DA:" "${merged_lcov}" 2>/dev/null || echo "0")
        covered_lines=$(grep "^DA:" "${merged_lcov}" 2>/dev/null | grep -cv ",0$" 2>/dev/null || echo "0")

        if [ "${total_lines}" -gt 0 ]; then
            percentage=$((covered_lines * 100 / total_lines))
            log_info "Line Coverage: ${percentage}% (${covered_lines}/${total_lines} lines)"
        else
            log_warn "No coverage data available for percentage calculation"
        fi
    fi
}

# ─── Test Summary ──────────────────────────────────────────────────────

print_summary() {
    print_separator
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           EXAMFORGE AI — TEST RESULTS SUMMARY            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Total Tests:  ${TOTAL_TESTS}"
    echo -e "  ${GREEN}Passed:       ${TOTAL_PASSED}${NC}"
    echo -e "  ${RED}Failed:       ${TOTAL_FAILED}${NC}"
    echo -e "  ${YELLOW}Skipped:      ${TOTAL_SKIPPED}${NC}"
    echo ""
    echo -e "  Results Directory: ${RESULTS_DIR}"
    echo -e "  Coverage Directory: ${COVERAGE_DIR}"
    echo ""

    if [ "${TOTAL_FAILED}" -gt 0 ]; then
        print_separator
        log_error "${TOTAL_FAILED} test(s) failed!"
        print_separator
        exit 1
    else
        print_separator
        log_success "All tests passed!"
        print_separator
        exit 0
    fi
}

# ─── Main ──────────────────────────────────────────────────────────────

main() {
    local test_type="${1:-all}"

    cd "${PROJECT_DIR}"

    log_info "ExamForge AI Test Runner"
    log_info "Project Directory: ${PROJECT_DIR}"
    log_info "Test Type: ${test_type}"
    echo ""

    check_flutter
    setup_results_dir

    case "${test_type}" in
        unit)
            run_unit_tests
            ;;
        widget)
            run_widget_tests
            ;;
        integration)
            run_integration_tests
            ;;
        domain)
            run_ccms_domain_tests
            ;;
        data)
            run_ccms_data_tests
            ;;
        security)
            run_ccms_security_tests
            ;;
        all)
            run_unit_tests
            run_widget_tests
            run_ccms_domain_tests
            run_ccms_data_tests
            run_ccms_security_tests
            run_integration_tests
            ;;
        *)
            log_error "Unknown test type: ${test_type}"
            echo "Usage: $0 {all|unit|widget|integration|domain|data|security}"
            exit 1
            ;;
    esac

    generate_coverage_report
    print_summary
}

main "$@"
