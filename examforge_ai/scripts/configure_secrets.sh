#!/bin/bash
# ============================================================================
# ExamForge AI — Edge Function Secret Configuration
# ============================================================================
# This script configures all required secrets for Supabase Edge Functions.
# Run this script ONCE during initial deployment or when secrets change.
#
# Usage: ./scripts/configure_secrets.sh
# ============================================================================

set -euo pipefail

# ─── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== ExamForge AI — Edge Function Secret Configuration ===${NC}"

# ─── Check Prerequisites ──────────────────────────────────────────────────
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}ERROR: supabase CLI is not installed${NC}"
    echo "Install it from: https://supabase.com/docs/guides/cli"
    exit 1
fi

# Check if project is linked
if ! supabase projects list &> /dev/null; then
    echo -e "${RED}ERROR: Not authenticated with Supabase. Run 'supabase login' first.${NC}"
    exit 1
fi

# ─── Project ID ────────────────────────────────────────────────────────────
PROJECT_REF="pzfnptrrnxkgodclyhft"

echo -e "${YELLOW}Configuring secrets for project: ${PROJECT_REF}${NC}"

# ─── Set Flutterwave Secrets ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}Setting Flutterwave secrets...${NC}"

# FLUTTERWAVE_SECRET_KEY (provided by user)
FLUTTERWAVE_SECRET_KEY="${FLUTTERWAVE_SECRET_KEY:-}"
if [ -z "$FLUTTERWAVE_SECRET_KEY" ]; then
    echo -e "${RED}ERROR: FLUTTERWAVE_SECRET_KEY environment variable is not set.${NC}"
    echo "Set it with: export FLUTTERWAVE_SECRET_KEY='your-secret-key'"
    exit 1
fi

supabase secrets set FLUTTERWAVE_SECRET_KEY="$FLUTTERWAVE_SECRET_KEY" --project-ref "$PROJECT_REF"
echo -e "${GREEN}✓ FLUTTERWAVE_SECRET_KEY configured${NC}"

# FLUTTERWAVE_WEBHOOK_SECRET_HASH (if provided)
FLUTTERWAVE_WEBHOOK_SECRET_HASH="${FLUTTERWAVE_WEBHOOK_SECRET_HASH:-}"
if [ -n "$FLUTTERWAVE_WEBHOOK_SECRET_HASH" ]; then
    supabase secrets set FLUTTERWAVE_WEBHOOK_SECRET_HASH="$FLUTTERWAVE_WEBHOOK_SECRET_HASH" --project-ref "$PROJECT_REF"
    echo -e "${GREEN}✓ FLUTTERWAVE_WEBHOOK_SECRET_HASH configured${NC}"
else
    echo -e "${YELLOW}⚠ FLUTTERWAVE_WEBHOOK_SECRET_HASH not provided — webhook verification will be disabled${NC}"
    echo "  Set it with: export FLUTTERWAVE_WEBHOOK_SECRET_HASH='your-webhook-hash'"
    echo "  Then re-run this script."
fi

# ─── Set AI Provider Secrets ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}Setting AI provider secrets...${NC}"

OPENAI_API_KEY="${OPENAI_API_KEY:-}"
if [ -n "$OPENAI_API_KEY" ]; then
    supabase secrets set OPENAI_API_KEY="$OPENAI_API_KEY" --project-ref "$PROJECT_REF"
    echo -e "${GREEN}✓ OPENAI_API_KEY configured${NC}"
else
    echo -e "${YELLOW}⚠ OPENAI_API_KEY not set — OpenAI features will be disabled${NC}"
fi

GEMINI_API_KEY="${GEMINI_API_KEY:-}"
if [ -n "$GEMINI_API_KEY" ]; then
    supabase secrets set GEMINI_API_KEY="$GEMINI_API_KEY" --project-ref "$PROJECT_REF"
    echo -e "${GREEN}✓ GEMINI_API_KEY configured${NC}"
else
    echo -e "${YELLOW}⚠ GEMINI_API_KEY not set — Gemini features will be disabled${NC}"
fi

# ─── Set FCM Secret ───────────────────────────────────────────────────────
FCM_SERVER_KEY="${FCM_SERVER_KEY:-}"
if [ -n "$FCM_SERVER_KEY" ]; then
    supabase secrets set FCM_SERVER_KEY="$FCM_SERVER_KEY" --project-ref "$PROJECT_REF"
    echo -e "${GREEN}✓ FCM_SERVER_KEY configured${NC}"
else
    echo -e "${YELLOW}⚠ FCM_SERVER_KEY not set — Push notifications may be limited${NC}"
fi

# ─── Set Environment ──────────────────────────────────────────────────────
ENVIRONMENT="${ENVIRONMENT:-production}"
supabase secrets set ENVIRONMENT="$ENVIRONMENT" --project-ref "$PROJECT_REF"
echo -e "${GREEN}✓ ENVIRONMENT set to $ENVIRONMENT${NC}"

# ─── Set App URL ──────────────────────────────────────────────────────────
APP_URL="${APP_URL:-https://app.examforge.ai}"
supabase secrets set APP_URL="$APP_URL" --project-ref "$PROJECT_REF"
echo -e "${GREEN}✓ APP_URL set to $APP_URL${NC}"

# ─── Verify ───────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Verifying secret configuration...${NC}"
supabase secrets list --project-ref "$PROJECT_REF"

echo ""
echo -e "${GREEN}=== Secret Configuration Complete ===${NC}"
echo ""
echo -e "Next steps:"
echo "  1. Deploy Edge Functions: supabase functions deploy --project-ref $PROJECT_REF"
echo "  2. Run database migrations: supabase db push --project-ref $PROJECT_REF"
echo "  3. Test the health check: curl https://$PROJECT_REF.supabase.co/functions/v1/health-check"
