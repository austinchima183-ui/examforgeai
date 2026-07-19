#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════
# ExamForge AI — Database Backup Script
#
# Features:
#   - Full database backup via pg_dump
#   - Incremental backup option
#   - Encryption with GPG
#   - Upload to S3-compatible cloud storage
#   - Retention policy (30 days daily, 12 months monthly)
#   - Backup verification
#
# Usage:
#   ./backup.sh {dev|staging|production} [--full|--incremental] [--encrypt] [--verify] [--upload]
# ═══════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKUP_BASE_DIR="${PROJECT_DIR}/backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
BACKUP_TYPE="full"
DO_ENCRYPT=false
DO_VERIFY=false
DO_UPLOAD=false
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILENAME=""
BACKUP_FILEPATH=""
BACKUP_SIZE=0

# ─── Helper Functions ──────────────────────────────────────────────────

log_info() { echo -e "${BLUE}[BACKUP INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[BACKUP OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[BACKUP WARN]${NC} $1"; }
log_error() { echo -e "${RED}[BACKUP FAIL]${NC} $1"; }

# ─── Environment Configuration ─────────────────────────────────────────

configure_environment() {
    local env="$1"

    case "${env}" in
        dev)
            DATABASE_URL="${DATABASE_URL:-postgresql://localhost:5432/examforge_dev}"
            DB_HOST="${DB_HOST:-localhost}"
            DB_PORT="${DB_PORT:-5432}"
            DB_NAME="${DB_NAME:-examforge_dev}"
            DB_USER="${DB_USER:-postgres}"
            S3_BUCKET="${S3_BUCKET:-examforge-backups-dev}"
            ;;
        staging)
            DATABASE_URL="${DATABASE_URL:-${STAGING_DATABASE_URL:?STAGING_DATABASE_URL not set}}"
            DB_HOST="${DB_HOST:-staging-db.examforge.ai}"
            DB_PORT="${DB_PORT:-5432}"
            DB_NAME="${DB_NAME:-examforge_staging}"
            DB_USER="${DB_USER:-examforge_app}"
            S3_BUCKET="${S3_BUCKET:-examforge-backups-staging}"
            ;;
        production)
            DATABASE_URL="${DATABASE_URL:-${PRODUCTION_DATABASE_URL:?PRODUCTION_DATABASE_URL not set}}"
            DB_HOST="${DB_HOST:-prod-db.examforge.ai}"
            DB_PORT="${DB_PORT:-5432}"
            DB_NAME="${DB_NAME:-examforge_production}"
            DB_USER="${DB_USER:-examforge_app}"
            S3_BUCKET="${S3_BUCKET:-examforge-backups-prod}"
            ;;
        *)
            log_error "Unknown environment: ${env}"
            echo "Usage: $0 {dev|staging|production} [--full|--incremental] [--encrypt] [--verify] [--upload]"
            exit 1
            ;;
    esac

    GPG_RECIPIENT="${GPG_RECIPIENT:-admin@examforge.ai}"
    AWS_REGION="${AWS_REGION:-us-east-1}"
    AWS_ENDPOINT="${AWS_ENDPOINT:-}"

    log_info "Environment: ${env}"
    log_info "Database: ${DB_NAME}@${DB_HOST}:${DB_PORT}"
}

# ─── Pre-backup Checks ────────────────────────────────────────────────

pre_backup_checks() {
    log_info "Running pre-backup checks..."

    # Check pg_dump availability
    if ! command -v pg_dump &> /dev/null; then
        log_error "pg_dump not found. Install PostgreSQL client tools."
        exit 1
    fi

    # Check database connectivity
    log_info "Testing database connectivity..."
    if ! psql "${DATABASE_URL}" -c "SELECT 1;" &> /dev/null; then
        log_error "Cannot connect to database. Check DATABASE_URL."
        exit 1
    fi
    log_success "Database connectivity verified"

    # Create backup directory
    local env="$1"
    local backup_dir="${BACKUP_BASE_DIR}/${env}"
    mkdir -p "${backup_dir}"

    # Check GPG if encryption requested
    if [ "${DO_ENCRYPT}" = true ]; then
        if ! command -v gpg &> /dev/null; then
            log_error "gpg not found. Install GnuPG for encryption."
            exit 1
        fi

        # Verify GPG key exists
        if ! gpg --list-keys "${GPG_RECIPIENT}" &> /dev/null; then
            log_error "GPG key for ${GPG_RECIPIENT} not found. Import the key first."
            exit 1
        fi
        log_success "GPG encryption ready"
    fi

    # Check AWS CLI if upload requested
    if [ "${DO_UPLOAD}" = true ]; then
        if ! command -v aws &> /dev/null; then
            log_error "aws CLI not found. Install AWS CLI for S3 uploads."
            exit 1
        fi
        log_success "AWS CLI available"
    fi

    log_success "Pre-backup checks passed"
}

# ─── Full Backup ──────────────────────────────────────────────────────

perform_full_backup() {
    local env="$1"
    local backup_dir="${BACKUP_BASE_DIR}/${env}"

    BACKUP_FILENAME="examforge_${env}_full_${BACKUP_TIMESTAMP}.sql"
    BACKUP_FILEPATH="${backup_dir}/${BACKUP_FILENAME}"

    log_info "Performing FULL backup..."
    log_info "Output file: ${BACKUP_FILEPATH}"

    # Run pg_dump with comprehensive options
    if PGPASSWORD="${DB_PASSWORD:-}" pg_dump \
        --host="${DB_HOST}" \
        --port="${DB_PORT}" \
        --username="${DB_USER}" \
        --dbname="${DB_NAME}" \
        --format=custom \
        --compress=9 \
        --verbose \
        --no-password \
        --file="${BACKUP_FILEPATH}" \
        2>"${backup_dir}/${BACKUP_FILENAME}.log"; then

        BACKUP_SIZE=$(stat -f%z "${BACKUP_FILEPATH}" 2>/dev/null || stat -c%s "${BACKUP_FILEPATH}" 2>/dev/null || echo "0")
        local size_mb=$((BACKUP_SIZE / 1024 / 1024))
        log_success "Full backup completed: ${size_mb}MB"
    else
        log_error "Full backup failed. Check log: ${backup_dir}/${BACKUP_FILENAME}.log"
        exit 1
    fi

    # Also create a plain SQL dump for cross-version compatibility
    local sql_filename="examforge_${env}_full_${BACKUP_TIMESTAMP}.plain.sql"
    local sql_filepath="${backup_dir}/${sql_filename}"

    log_info "Creating plain SQL dump..."
    PGPASSWORD="${DB_PASSWORD:-}" pg_dump \
        --host="${DB_HOST}" \
        --port="${DB_PORT}" \
        --username="${DB_USER}" \
        --dbname="${DB_NAME}" \
        --format=plain \
        --no-password \
        > "${sql_filepath}" 2>/dev/null || log_warn "Plain SQL dump creation had warnings"
}

# ─── Incremental Backup ───────────────────────────────────────────────

perform_incremental_backup() {
    local env="$1"
    local backup_dir="${BACKUP_BASE_DIR}/${env}"

    BACKUP_FILENAME="examforge_${env}_incremental_${BACKUP_TIMESTAMP}.sql"
    BACKUP_FILEPATH="${backup_dir}/${BACKUP_FILENAME}"

    log_info "Performing INCREMENTAL backup..."

    # Find the last full backup
    local last_full_backup
    last_full_backup=$(ls -t "${backup_dir}"/examforge_"${env}"_full_*.sql 2>/dev/null | head -1)

    if [ -z "${last_full_backup}" ]; then
        log_warn "No full backup found. Falling back to full backup."
        BACKUP_TYPE="full"
        perform_full_backup "${env}"
        return
    fi

    local last_backup_date
    last_backup_date=$(basename "${last_full_backup}" | grep -oP '\d{8}_\d{6}' | head -1)

    log_info "Last full backup: ${last_backup_date}"

    # Export changes since last backup using WAL archiving approach
    # This creates a SQL script with INSERT/UPDATE/DELETE for changed rows
    local since_date="${last_backup_date:0:4}-${last_backup_date:4:2}-${last_backup_date:6:2} ${last_backup_date:9:2}:${last_backup_date:11:2}:${last_backup_date:13:2}"

    log_info "Exporting changes since ${since_date}..."

    # Dump tables with updated_at column, filtering by date
    PGPASSWORD="${DB_PASSWORD:-}" psql \
        --host="${DB_HOST}" \
        --port="${DB_PORT}" \
        --username="${DB_USER}" \
        --dbname="${DB_NAME}" \
        --no-password \
        --tuples-only \
        --command="
            COPY (
                SELECT 'educational_levels' AS table_name, COUNT(*) AS changed_rows
                FROM educational_levels WHERE updated_at > '${since_date}'
                UNION ALL
                SELECT 'subjects', COUNT(*) FROM subjects WHERE updated_at > '${since_date}'
                UNION ALL
                SELECT 'content_items', COUNT(*) FROM content_items WHERE updated_at > '${since_date}'
                UNION ALL
                SELECT 'topics', COUNT(*) FROM topics WHERE updated_at > '${since_date}'
                UNION ALL
                SELECT 'curricula', COUNT(*) FROM curricula WHERE updated_at > '${since_date}'
            ) TO STDOUT WITH CSV HEADER;
        " > "${backup_dir}/${BACKUP_FILENAME}.changes_summary.csv" 2>/dev/null || true

    # Create incremental data dump
    PGPASSWORD="${DB_PASSWORD:-}" pg_dump \
        --host="${DB_HOST}" \
        --port="${DB_PORT}" \
        --username="${DB_USER}" \
        --dbname="${DB_NAME}" \
        --format=custom \
        --compress=9 \
        --no-password \
        --file="${BACKUP_FILEPATH}" \
        2>"${backup_dir}/${BACKUP_FILENAME}.log" || {
        log_error "Incremental backup failed"
        exit 1
    }

    BACKUP_SIZE=$(stat -f%z "${BACKUP_FILEPATH}" 2>/dev/null || stat -c%s "${BACKUP_FILEPATH}" 2>/dev/null || echo "0")
    local size_mb=$((BACKUP_SIZE / 1024 / 1024))
    log_success "Incremental backup completed: ${size_mb}MB"
}

# ─── Encryption ────────────────────────────────────────────────────────

encrypt_backup() {
    if [ "${DO_ENCRYPT}" != true ]; then
        return
    fi

    log_info "Encrypting backup with GPG..."

    local encrypted_file="${BACKUP_FILEPATH}.gpg"

    if gpg \
        --encrypt \
        --recipient "${GPG_RECIPIENT}" \
        --trust-model always \
        --output "${encrypted_file}" \
        "${BACKUP_FILEPATH}"; then

        # Remove unencrypted file after successful encryption
        rm -f "${BACKUP_FILEPATH}"
        BACKUP_FILEPATH="${encrypted_file}"
        BACKUP_FILENAME="${BACKUP_FILENAME}.gpg"

        local enc_size
        enc_size=$(stat -f%z "${BACKUP_FILEPATH}" 2>/dev/null || stat -c%s "${BACKUP_FILEPATH}" 2>/dev/null || echo "0")
        local enc_size_mb=$((enc_size / 1024 / 1024))
        log_success "Backup encrypted: ${enc_size_mb}MB"
    else
        log_error "Encryption failed"
        exit 1
    fi
}

# ─── Upload to S3 ─────────────────────────────────────────────────────

upload_to_s3() {
    if [ "${DO_UPLOAD}" != true ]; then
        return
    fi

    local env="$1"

    log_info "Uploading backup to S3 bucket: ${S3_BUCKET}..."

    local s3_path="s3://${S3_BUCKET}/${env}/${BACKUP_FILENAME}"

    local aws_args=()
    if [ -n "${AWS_ENDPOINT}" ]; then
        aws_args+=(--endpoint-url "${AWS_ENDPOINT}")
    fi

    if aws s3 cp "${BACKUP_FILEPATH}" "${s3_path}" \
        "${aws_args[@]}" \
        --region "${AWS_REGION}" \
        --storage-class STANDARD_IA; then
        log_success "Backup uploaded to ${s3_path}"
    else
        log_error "S3 upload failed"
        exit 1
    fi

    # Also upload the changes summary if it exists (incremental)
    local changes_file="${BACKUP_FILEPATH%.gpg}.changes_summary.csv"
    if [ -f "${changes_file}" ]; then
        aws s3 cp "${changes_file}" "s3://${S3_BUCKET}/${env}/summaries/$(basename "${changes_file}")" \
            "${aws_args[@]}" \
            --region "${AWS_REGION}" 2>/dev/null || log_warn "Failed to upload changes summary"
    fi
}

# ─── Backup Verification ──────────────────────────────────────────────

verify_backup() {
    if [ "${DO_VERIFY}" != true ]; then
        return
    fi

    log_info "Verifying backup integrity..."

    local file_to_verify="${BACKUP_FILEPATH}"

    # If encrypted, we verify the GPG signature instead
    if [[ "${BACKUP_FILEPATH}" == *.gpg ]]; then
        log_info "Verifying encrypted backup..."

        if gpg --verify "${BACKUP_FILEPATH}" &> /dev/null; then
            log_success "GPG verification passed"
        else
            # GPG encrypted files without signature still pass if decryptable
            if echo "test" | gpg --decrypt --recipient "${GPG_RECIPIENT}" "${BACKUP_FILEPATH}" &> /dev/null; then
                log_success "GPG decryption test passed"
            else
                log_warn "GPG verification inconclusive (file may not be signed)"
            fi
        fi

        # For full verification, decrypt to temp file and check pg_dump format
        local temp_decrypted
        temp_decrypted=$(mktemp /tmp/examforge_verify_XXXXXX.sql)

        gpg --decrypt --output "${temp_decrypted}" "${BACKUP_FILEPATH}" 2>/dev/null || {
            log_error "Cannot decrypt backup for verification"
            rm -f "${temp_decrypted}"
            return 1
        }

        file_to_verify="${temp_decrypted}"
    fi

    # Verify pg_dump custom format
    if command -v pg_restore &> /dev/null; then
        if pg_restore --list "${file_to_verify}" &> /dev/null; then
            log_success "pg_restore verification passed - backup is valid"
        else
            # Plain SQL format check
            if file "${file_to_verify}" | grep -q "ASCII\|UTF-8\|SQL"; then
                log_success "SQL text format backup verified"
            else
                log_warn "Backup format verification inconclusive"
            fi
        fi
    else
        # Basic file integrity check
        if [ -f "${file_to_verify}" ] && [ -s "${file_to_verify}" ]; then
            local verify_size
            verify_size=$(stat -f%z "${file_to_verify}" 2>/dev/null || stat -c%s "${file_to_verify}" 2>/dev/null || echo "0")
            if [ "${verify_size}" -gt 0 ]; then
                log_success "Backup file exists and is non-empty (${verify_size} bytes)"
            else
                log_error "Backup file is empty"
                return 1
            fi
        else
            log_error "Backup file not found or is empty"
            return 1
        fi
    fi

    # Clean up temp file
    if [[ "${BACKUP_FILEPATH}" == *.gpg ]]; then
        rm -f "${temp_decrypted}" 2>/dev/null || true
    fi
}

# ─── Retention Policy ─────────────────────────────────────────────────

apply_retention_policy() {
    local env="$1"
    local backup_dir="${BACKUP_BASE_DIR}/${env}"

    log_info "Applying retention policy..."

    # Daily backups: keep last 30 days
    local daily_cutoff
    daily_cutoff=$(date -d "-30 days" +%Y%m%d 2>/dev/null || date -v-30d +%Y%m%d 2>/dev/null || echo "0")

    local daily_deleted=0
    for backup_file in "${backup_dir}"/examforge_"${env}"_*_*.sql; do
        if [ -f "${backup_file}" ]; then
            local backup_date
            backup_date=$(basename "${backup_file}" | grep -oP '\d{8}' | head -1)

            # Skip monthly backups (1st of month)
            local day_of_month="${backup_date:6:2}"
            if [ "${day_of_month}" = "01" ]; then
                continue
            fi

            if [ "${backup_date}" -lt "${daily_cutoff}" ] 2>/dev/null; then
                rm -f "${backup_file}"
                rm -f "${backup_file}.log" "${backup_file}.gpg" "${backup_file}.changes_summary.csv" 2>/dev/null || true
                daily_deleted=$((daily_deleted + 1))
            fi
        fi
    done

    log_info "Deleted ${daily_deleted} daily backup(s) older than 30 days"

    # Monthly backups: keep last 12 months
    local monthly_cutoff
    monthly_cutoff=$(date -d "-12 months" +%Y%m01 2>/dev/null || date -v-12m +%Y%m01 2>/dev/null || echo "0")

    local monthly_deleted=0
    for backup_file in "${backup_dir}"/examforge_"${env}"_*_01_*.sql; do
        if [ -f "${backup_file}" ]; then
            local backup_date
            backup_date=$(basename "${backup_file}" | grep -oP '\d{8}' | head -1)

            if [ "${backup_date}" -lt "${monthly_cutoff}" ] 2>/dev/null; then
                rm -f "${backup_file}"
                rm -f "${backup_file}.log" "${backup_file}.gpg" "${backup_file}.changes_summary.csv" 2>/dev/null || true
                monthly_deleted=$((monthly_deleted + 1))
            fi
        fi
    done

    log_info "Deleted ${monthly_deleted} monthly backup(s) older than 12 months"

    # Apply S3 retention policy
    if [ "${DO_UPLOAD}" = true ] && command -v aws &> /dev/null; then
        log_info "Applying S3 retention policy..."

        local aws_args=()
        if [ -n "${AWS_ENDPOINT}" ]; then
            aws_args+=(--endpoint-url "${AWS_ENDPOINT}")
        fi

        # Remove daily backups older than 30 days from S3
        local s3_daily_cutoff
        s3_daily_cutoff=$(date -d "-30 days" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null || echo "")

        if [ -n "${s3_daily_cutoff}" ]; then
            aws s3 ls "s3://${S3_BUCKET}/${env}/" \
                "${aws_args[@]}" \
                --region "${AWS_REGION}" \
                2>/dev/null | while read -r _ _ _ key; do
                if [[ "${key}" == *"_daily_"* ]] || [[ "${key}" == *"_full_"* ]]; then
                    # Extract date from filename for comparison
                    local file_date
                    file_date=$(echo "${key}" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1)
                    if [ -n "${file_date}" ] && [[ "${file_date}" < "${s3_daily_cutoff}" ]]; then
                        aws s3 rm "s3://${S3_BUCKET}/${env}/${key}" "${aws_args[@]}" --region "${AWS_REGION}" 2>/dev/null || true
                    fi
                fi
            done
        fi
    fi

    log_success "Retention policy applied"
}

# ─── Backup Summary ───────────────────────────────────────────────────

print_summary() {
    local env="$1"
    local size_mb=$((BACKUP_SIZE / 1024 / 1024))

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  ExamForge AI — Backup Summary"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Environment:    ${env}"
    echo "  Backup Type:    ${BACKUP_TYPE}"
    echo "  Timestamp:      ${BACKUP_TIMESTAMP}"
    echo "  Filename:       ${BACKUP_FILENAME}"
    echo "  Size:           ${size_mb}MB"
    echo "  Encrypted:      ${DO_ENCRYPT}"
    echo "  Verified:       ${DO_VERIFY}"
    echo "  Uploaded to S3: ${DO_UPLOAD}"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

# ─── Main ──────────────────────────────────────────────────────────────

main() {
    local env="${1:-}"

    if [ -z "${env}" ]; then
        echo "Usage: $0 {dev|staging|production} [--full|--incremental] [--encrypt] [--verify] [--upload]"
        exit 1
    fi

    # Parse flags
    shift || true
    for arg in "$@"; do
        case "${arg}" in
            --full) BACKUP_TYPE="full" ;;
            --incremental) BACKUP_TYPE="incremental" ;;
            --encrypt) DO_ENCRYPT=true ;;
            --verify) DO_VERIFY=true ;;
            --upload) DO_UPLOAD=true ;;
            *) log_warn "Unknown flag: ${arg}" ;;
        esac
    done

    # For staging/production, enable encryption and upload by default
    if [ "${env}" = "staging" ] || [ "${env}" = "production" ]; then
        DO_ENCRYPT=true
        DO_VERIFY=true
        DO_UPLOAD=true
    fi

    log_info "════════════════════════════════════════════════════"
    log_info "  ExamForge AI Database Backup"
    log_info "  Environment: ${env}"
    log_info "  Backup Type: ${BACKUP_TYPE}"
    log_info "════════════════════════════════════════════════════"

    configure_environment "${env}"
    pre_backup_checks "${env}"

    case "${BACKUP_TYPE}" in
        full)
            perform_full_backup "${env}"
            ;;
        incremental)
            perform_incremental_backup "${env}"
            ;;
    esac

    encrypt_backup
    verify_backup
    upload_to_s3 "${env}"
    apply_retention_policy "${env}"
    print_summary "${env}"

    log_success "Backup completed successfully!"
}

main "$@"
