#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
# ExamForge AI — Deployment Script
#
# Multi-environment deployment: dev, staging, prod
# Features: database migration, health check, rollback, blue-green
# ═══════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEPLOY_DIR="${PROJECT_DIR}/deploy"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Deployment state
DEPLOY_ID=""
PREVIOUS_VERSION=""
CURRENT_VERSION=""
ROLLBACK_NEEDED=false

# ─── Helper Functions ──────────────────────────────────────────────────

log_info() { echo -e "${BLUE}[DEPLOY INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[DEPLOY OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[DEPLOY WARN]${NC} $1"; }
log_error() { echo -e "${RED}[DEPLOY FAIL]${NC} $1"; }

generate_deploy_id() {
    DEPLOY_ID="deploy-$(date +%Y%m%d%H%M%S)-$(openssl rand -hex 4)"
    echo "${DEPLOY_ID}"
}

# ─── Environment Configuration ─────────────────────────────────────────

get_env_config() {
    local env="$1"

    case "${env}" in
        dev)
            export DATABASE_URL="${DATABASE_URL:-postgresql://localhost:5432/examforge_dev}"
            export APP_URL="${APP_URL:-http://localhost:3000}"
            export API_URL="${API_URL:-http://localhost:3001}"
            export SUPABASE_URL="${SUPABASE_URL:-http://localhost:54321}"
            export SUPABASE_SERVICE_KEY="${SUPABASE_SERVICE_KEY:-dev-key}"
            export DEPLOY_HOST="${DEPLOY_HOST:-localhost}"
            export DEPLOY_USER="${DEPLOY_USER:-developer}"
            export DEPLOY_PATH="${DEPLOY_PATH:-/var/www/examforge-dev}"
            export HEALTH_CHECK_URL="${APP_URL}/health"
            export BACKUP_ENABLED="${BACKUP_ENABLED:-false}"
            export ROLLBACK_ENABLED="${ROLLBACK_ENABLED:-true}"
            ;;
        staging)
            export DATABASE_URL="${DATABASE_URL:-${STAGING_DATABASE_URL:?STAGING_DATABASE_URL not set}}"
            export APP_URL="${APP_URL:-https://staging.examforge.ai}"
            export API_URL="${API_URL:-https://staging-api.examforge.ai}"
            export SUPABASE_URL="${SUPABASE_URL:-${STAGING_SUPABASE_URL:?STAGING_SUPABASE_URL not set}}"
            export SUPABASE_SERVICE_KEY="${SUPABASE_SERVICE_KEY:-${STAGING_SUPABASE_SERVICE_KEY:?STAGING_SUPABASE_SERVICE_KEY not set}}"
            export DEPLOY_HOST="${STAGING_HOST:?STAGING_HOST not set}"
            export DEPLOY_USER="${STAGING_USER:-deploy}"
            export DEPLOY_PATH="${DEPLOY_PATH:-/var/www/examforge-staging}"
            export HEALTH_CHECK_URL="${APP_URL}/health"
            export BACKUP_ENABLED="${BACKUP_ENABLED:-true}"
            export ROLLBACK_ENABLED="${ROLLBACK_ENABLED:-true}"
            ;;
        production)
            export DATABASE_URL="${DATABASE_URL:-${PRODUCTION_DATABASE_URL:?PRODUCTION_DATABASE_URL not set}}"
            export APP_URL="${APP_URL:-https://examforge.ai}"
            export API_URL="${API_URL:-https://api.examforge.ai}"
            export SUPABASE_URL="${SUPABASE_URL:-${PRODUCTION_SUPABASE_URL:?PRODUCTION_SUPABASE_URL not set}}"
            export SUPABASE_SERVICE_KEY="${SUPABASE_SERVICE_KEY:-${PRODUCTION_SUPABASE_SERVICE_KEY:?PRODUCTION_SUPABASE_SERVICE_KEY not set}}"
            export DEPLOY_HOST="${PRODUCTION_HOST:?PRODUCTION_HOST not set}"
            export DEPLOY_USER="${PRODUCTION_USER:-deploy}"
            export DEPLOY_PATH="${DEPLOY_PATH:-/var/www/examforge}"
            export HEALTH_CHECK_URL="${APP_URL}/health"
            export BACKUP_ENABLED="${BACKUP_ENABLED:-true}"
            export ROLLBACK_ENABLED="${ROLLBACK_ENABLED:-true}"
            ;;
        *)
            log_error "Unknown environment: ${env}"
            echo "Usage: $0 {dev|staging|production} [--migrate-only] [--health-check] [--rollback] [--blue-green]"
            exit 1
            ;;
    esac

    log_info "Environment configured: ${env}"
    log_info "App URL: ${APP_URL}"
    log_info "Deploy Host: ${DEPLOY_HOST}"
}

# ─── Pre-deployment Checks ─────────────────────────────────────────────

pre_deploy_checks() {
    local env="$1"

    log_info "Running pre-deployment checks for ${env}..."

    # Check required tools
    for cmd in flutter psql; do
        if ! command -v "${cmd}" &> /dev/null; then
            log_warn "${cmd} not found in PATH - some steps may be skipped"
        fi
    done

    # Check build artifacts exist for staging/production
    if [ "${env}" != "dev" ]; then
        if [ ! -d "${PROJECT_DIR}/build/web" ]; then
            log_error "Web build artifacts not found. Run 'flutter build web' first."
            exit 1
        fi
    fi

    # Verify environment variables
    if [ -z "${DATABASE_URL:-}" ]; then
        log_error "DATABASE_URL is not set"
        exit 1
    fi

    # Check disk space (at least 500MB free)
    local available_kb
    available_kb=$(df -k "${DEPLOY_PATH:-/tmp}" 2>/dev/null | awk 'NR==2{print $4}' || echo "999999")
    if [ "${available_kb}" -lt 512000 ]; then
        log_error "Insufficient disk space: ${available_kb}KB available (need 512000KB)"
        exit 1
    fi

    # Record current version for rollback
    PREVIOUS_VERSION=$(get_current_version "${env}")
    log_info "Current deployed version: ${PREVIOUS_VERSION}"

    log_success "Pre-deployment checks passed"
}

# ─── Database Migration ────────────────────────────────────────────────

run_database_migrations() {
    local env="$1"

    log_info "Running database migrations for ${env}..."

    # Create migration tracking table if not exists
    psql "${DATABASE_URL}" -c "
        CREATE TABLE IF NOT EXISTS _deploy_migrations (
            id SERIAL PRIMARY KEY,
            deploy_id VARCHAR(100) NOT NULL,
            migration_name VARCHAR(255) NOT NULL,
            applied_at TIMESTAMP DEFAULT NOW(),
            rolled_back_at TIMESTAMP
        );
    " 2>/dev/null || log_warn "Could not create migration tracking table"

    # Run pending migrations
    local migrations_dir="${PROJECT_DIR}/supabase/migrations"

    if [ -d "${migrations_dir}" ]; then
        local migration_count=0
        for migration_file in "${migrations_dir}"/*.sql; do
            if [ -f "${migration_file}" ]; then
                local migration_name
                migration_name=$(basename "${migration_file}")

                # Check if migration already applied
                local already_applied
                already_applied=$(psql "${DATABASE_URL}" -t -c \
                    "SELECT COUNT(*) FROM _deploy_migrations WHERE migration_name='${migration_name}' AND rolled_back_at IS NULL;" \
                    2>/dev/null | tr -d ' ' || echo "0")

                if [ "${already_applied}" = "0" ]; then
                    log_info "Applying migration: ${migration_name}"

                    if psql "${DATABASE_URL}" -f "${migration_file}" 2>/dev/null; then
                        psql "${DATABASE_URL}" -c \
                            "INSERT INTO _deploy_migrations (deploy_id, migration_name) VALUES ('${DEPLOY_ID}', '${migration_name}');" \
                            2>/dev/null || true
                        migration_count=$((migration_count + 1))
                        log_success "Migration applied: ${migration_name}"
                    else
                        log_error "Migration failed: ${migration_name}"
                        ROLLBACK_NEEDED=true
                        return 1
                    fi
                else
                    log_info "Migration already applied: ${migration_name}"
                fi
            fi
        done

        log_success "Applied ${migration_count} migration(s)"
    else
        log_warn "No migrations directory found at ${migrations_dir}"
    fi
}

# ─── Backup Before Deploy ─────────────────────────────────────────────

run_pre_deploy_backup() {
    local env="$1"

    if [ "${BACKUP_ENABLED}" = "true" ]; then
        log_info "Running pre-deployment backup for ${env}..."
        if [ -f "${SCRIPT_DIR}/backup.sh" ]; then
            chmod +x "${SCRIPT_DIR}/backup.sh"
            "${SCRIPT_DIR}/backup.sh" "${env}" --full || log_warn "Backup failed, continuing anyway"
        else
            log_warn "Backup script not found, skipping pre-deploy backup"
        fi
    fi
}

# ─── Deploy Application ───────────────────────────────────────────────

deploy_application() {
    local env="$1"

    log_info "Deploying application to ${env}..."

    CURRENT_VERSION="${DEPLOY_ID}"

    case "${env}" in
        dev)
            deploy_dev
            ;;
        staging|production)
            if [ "${DEPLOY_STRATEGY:-standard}" = "blue-green" ]; then
                deploy_blue_green "${env}"
            else
                deploy_standard "${env}"
            fi
            ;;
    esac

    # Record deployment version
    echo "${CURRENT_VERSION}" > "${DEPLOY_DIR}/${env}-version.txt"

    log_success "Application deployed successfully (version: ${CURRENT_VERSION})"
}

deploy_dev() {
    log_info "Starting dev server..."
    flutter run -d chrome --dart-define=ENVIRONMENT=dev &
    log_success "Dev server started"
}

deploy_standard() {
    local env="$1"

    log_info "Performing standard deployment to ${env}..."

    # Create deployment directory
    ssh "${DEPLOY_USER}@${DEPLOY_HOST}" "mkdir -p ${DEPLOY_PATH}/releases/${DEPLOY_ID}" 2>/dev/null || true

    # Sync build artifacts to remote server
    rsync -avz --delete \
        "${PROJECT_DIR}/build/web/" \
        "${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/releases/${DEPLOY_ID}/" \
        2>/dev/null || {
        log_error "Failed to sync build artifacts"
        ROLLBACK_NEEDED=true
        return 1
    }

    # Update current symlink
    ssh "${DEPLOY_USER}@${DEPLOY_HOST}" \
        "cd ${DEPLOY_PATH} && ln -sfn releases/${DEPLOY_ID} current" \
        2>/dev/null || {
        log_error "Failed to update symlink"
        ROLLBACK_NEEDED=true
        return 1
    }

    # Restart application server
    ssh "${DEPLOY_USER}@${DEPLOY_HOST}" \
        "sudo systemctl reload nginx 2>/dev/null || sudo systemctl reload examforge 2>/dev/null || true" \
        2>/dev/null || true

    log_success "Standard deployment completed"
}

deploy_blue_green() {
    local env="$1"

    log_info "Performing blue-green deployment to ${env}..."

    # Determine current active slot (blue or green)
    local current_slot
    current_slot=$(ssh "${DEPLOY_USER}@${DEPLOY_HOST}" \
        "readlink ${DEPLOY_PATH}/current 2>/dev/null | xargs basename" 2>/dev/null || echo "blue")

    local target_slot
    if [ "${current_slot}" = "blue" ]; then
        target_slot="green"
    else
        target_slot="blue"
    fi

    log_info "Current slot: ${current_slot}, deploying to: ${target_slot}"

    # Deploy to target slot
    ssh "${DEPLOY_USER}@${DEPLOY_HOST}" "mkdir -p ${DEPLOY_PATH}/${target_slot}" 2>/dev/null || true

    rsync -avz --delete \
        "${PROJECT_DIR}/build/web/" \
        "${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/${target_slot}/" \
        2>/dev/null || {
        log_error "Failed to sync to ${target_slot} slot"
        ROLLBACK_NEEDED=true
        return 1
    }

    # Health check on target slot before switching
    local target_url
    if [ "${target_slot}" = "green" ]; then
        target_url="${APP_URL/api-/api-green-/}"
    else
        target_url="${APP_URL/api-/api-blue-/}"
    fi

    log_info "Running health check on ${target_slot} slot..."
    if ! health_check_internal "${target_url}/health" 3 5; then
        log_error "Health check failed on ${target_slot} slot. Not switching traffic."
        ROLLBACK_NEEDED=true
        return 1
    fi

    # Switch traffic to target slot
    ssh "${DEPLOY_USER}@${DEPLOY_HOST}" \
        "cd ${DEPLOY_PATH} && ln -sfn ${target_slot} current" \
        2>/dev/null || {
        log_error "Failed to switch to ${target_slot} slot"
        ROLLBACK_NEEDED=true
        return 1
    }

    # Reload server
    ssh "${DEPLOY_USER}@${DEPLOY_HOST}" \
        "sudo systemctl reload nginx 2>/dev/null || sudo systemctl reload examforge 2>/dev/null || true" \
        2>/dev/null || true

    log_success "Blue-green deployment completed. Traffic switched to ${target_slot}."
}

# ─── Health Check ──────────────────────────────────────────────────────

health_check_internal() {
    local url="$1"
    local max_retries="${2:-5}"
    local retry_interval="${3:-10}"

    log_info "Health check: ${url} (max retries: ${max_retries}, interval: ${retry_interval}s)"

    for i in $(seq 1 "${max_retries}"); do
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null || echo "000")

        if [ "${http_code}" = "200" ]; then
            log_success "Health check passed (attempt ${i}/${max_retries})"
            return 0
        fi

        log_warn "Health check failed (attempt ${i}/${max_retries}, HTTP ${http_code}). Retrying in ${retry_interval}s..."
        sleep "${retry_interval}"
    done

    log_error "Health check failed after ${max_retries} attempts"
    return 1
}

health_check() {
    local env="$1"

    log_info "Running health check for ${env}..."

    if health_check_internal "${HEALTH_CHECK_URL}" 5 10; then
        log_success "Application is healthy at ${APP_URL}"
        return 0
    else
        log_error "Application health check failed at ${APP_URL}"
        ROLLBACK_NEEDED=true
        return 1
    fi
}

# ─── Rollback ──────────────────────────────────────────────────────────

rollback() {
    local env="$1"

    log_warn "Initiating rollback for ${env}..."

    if [ -z "${PREVIOUS_VERSION}" ] || [ "${PREVIOUS_VERSION}" = "none" ]; then
        log_error "No previous version available for rollback"
        return 1
    fi

    log_info "Rolling back to version: ${PREVIOUS_VERSION}"

    # Restore previous deployment symlink
    ssh "${DEPLOY_USER}@${DEPLOY_HOST}" \
        "cd ${DEPLOY_PATH} && ln -sfn releases/${PREVIOUS_VERSION} current" \
        2>/dev/null || {
        log_error "Failed to rollback symlink"
        return 1
    }

    # Reload server
    ssh "${DEPLOY_USER}@${DEPLOY_HOST}" \
        "sudo systemctl reload nginx 2>/dev/null || sudo systemctl reload examforge 2>/dev/null || true" \
        2>/dev/null || true

    # Verify rollback health
    sleep 5
    if health_check_internal "${HEALTH_CHECK_URL}" 3 10; then
        log_success "Rollback completed successfully. Version: ${PREVIOUS_VERSION}"
    else
        log_error "Rollback health check failed. Manual intervention required."
        return 1
    fi
}

# ─── Post-deployment ──────────────────────────────────────────────────

post_deploy() {
    local env="$1"

    log_info "Running post-deployment tasks for ${env}..."

    # Clear caches
    log_info "Clearing application caches..."
    ssh "${DEPLOY_USER}@${DEPLOY_HOST}" \
        "rm -rf ${DEPLOY_PATH}/current/.cache 2>/dev/null || true" \
        2>/dev/null || true

    # Warm up caches
    curl -s "${APP_URL}" > /dev/null 2>&1 || true

    # Clean up old releases (keep last 5)
    log_info "Cleaning up old releases..."
    ssh "${DEPLOY_USER}@${DEPLOY_HOST}" \
        "cd ${DEPLOY_PATH}/releases && ls -t | tail -n +6 | xargs -r rm -rf" \
        2>/dev/null || true

    log_success "Post-deployment tasks completed"
}

# ─── Version Tracking ─────────────────────────────────────────────────

get_current_version() {
    local env="$1"

    if [ -f "${DEPLOY_DIR}/${env}-version.txt" ]; then
        cat "${DEPLOY_DIR}/${env}-version.txt"
    else
        echo "none"
    fi
}

# ─── Main ──────────────────────────────────────────────────────────────

main() {
    local env="${1:-}"
    local migrate_only=false
    local health_check_only=false
    local do_rollback=false
    local deploy_strategy="standard"

    if [ -z "${env}" ]; then
        echo "Usage: $0 {dev|staging|production} [--migrate-only] [--health-check] [--rollback] [--blue-green]"
        exit 1
    fi

    # Parse flags
    shift || true
    for arg in "$@"; do
        case "${arg}" in
            --migrate-only) migrate_only=true ;;
            --health-check) health_check_only=true ;;
            --rollback) do_rollback=true ;;
            --blue-green) deploy_strategy="blue-green" ;;
            *) log_warn "Unknown flag: ${arg}" ;;
        esac
    done

    # Setup
    DEPLOY_ID=$(generate_deploy_id)
    DEPLOY_STRATEGY="${deploy_strategy}"
    mkdir -p "${DEPLOY_DIR}"

    get_env_config "${env}"

    # Handle special modes
    if [ "${do_rollback}" = "true" ]; then
        PREVIOUS_VERSION=$(get_current_version "${env}")
        rollback "${env}"
        exit $?
    fi

    if [ "${health_check_only}" = "true" ]; then
        health_check "${env}"
        exit $?
    fi

    if [ "${migrate_only}" = "true" ]; then
        run_database_migrations "${env}"
        exit $?
    fi

    # Full deployment pipeline
    log_info "════════════════════════════════════════════════════"
    log_info "  ExamForge AI Deployment"
    log_info "  Environment: ${env}"
    log_info "  Deploy ID: ${DEPLOY_ID}"
    log_info "  Strategy: ${DEPLOY_STRATEGY}"
    log_info "════════════════════════════════════════════════════"

    pre_deploy_checks "${env}"
    run_pre_deploy_backup "${env}"
    run_database_migrations "${env}"

    if [ "${ROLLBACK_NEEDED}" = "true" ]; then
        log_error "Migration failed, initiating rollback..."
        rollback "${env}"
        exit 1
    fi

    deploy_application "${env}"

    if [ "${ROLLBACK_NEEDED}" = "true" ]; then
        log_error "Deployment failed, initiating rollback..."
        rollback "${env}"
        exit 1
    fi

    if health_check "${env}"; then
        post_deploy "${env}"
        log_success "════════════════════════════════════════════════════"
        log_success "  Deployment successful!"
        log_success "  Environment: ${env}"
        log_success "  Version: ${CURRENT_VERSION}"
        log_success "  URL: ${APP_URL}"
        log_success "════════════════════════════════════════════════════"
    else
        log_error "Health check failed after deployment"
        if [ "${ROLLBACK_ENABLED}" = "true" ]; then
            rollback "${env}"
        fi
        exit 1
    fi
}

main "$@"
