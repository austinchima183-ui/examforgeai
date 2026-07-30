// ============================================================================
// ExamForge AI — Secure Refund Processing Edge Function
// ============================================================================
// Provides server-side refund validation and processing.
//
// SECURITY MODEL:
//   1. Authenticated and authorized request (super_admin or school_admin only)
//   2. Original transaction must exist and be successful
//   3. Refund amount must be valid (positive, not exceeding original payment)
//   4. Duplicate refunds for the same transaction are rejected
//   5. Total refunds cannot exceed the original payment amount
//   6. Every refund attempt is audit-logged
//   7. Refund is processed via Flutterwave API with validation
//
// ROOT CAUSE (why this file exists):
// The original processRefund() in FlutterwaveDataSourceImpl called the
// Flutterwave refund API directly without any server-side validation.
// An attacker could:
//   - Refund a non-existent transaction
//   - Refund more than the original payment
//   - Issue duplicate refunds for the same transaction
//   - Refund a transaction that was already fully refunded
//   - Issue refunds without proper authorization
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ─── CORS Configuration (Hardened) ────────────────────────────────────────
const ALLOWED_ORIGINS = (() => {
  const env = Deno.env.get('ENVIRONMENT') || 'development';
  switch (env) {
    case 'production':
      return [
        'https://examforge.ai',
        'https://www.examforge.ai',
        'https://app.examforge.ai',
        'https://admin.examforge.ai',
      ];
    case 'staging':
      return [
        'https://staging.examforge.ai',
        'https://staging-app.examforge.ai',
      ];
    default:
      return [
        'http://localhost:3000',
        'http://localhost:5173',
        'http://127.0.0.1:3000',
        'http://127.0.0.1:5173',
      ];
  }
})();

function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get('Origin') || '';
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  };
}

// ─── Authorization check ──────────────────────────────────────────────────
async function isAuthorized(
  userClient: any,
  userId: string
): Promise<{ authorized: boolean; role?: string; schoolId?: string }> {
  const { data: userProfile, error } = await userClient
    .from('users')
    .select('role, school_id')
    .eq('id', userId)
    .maybeSingle();

  if (error || !userProfile) {
    return { authorized: false };
  }

  const allowedRoles = ['super_admin', 'school_admin'];
  if (!allowedRoles.includes(userProfile.role)) {
    return { authorized: false, role: userProfile.role };
  }

  return {
    authorized: true,
    role: userProfile.role,
    schoolId: userProfile.school_id,
  };
}

// ─── Audit logging ────────────────────────────────────────────────────────
async function logRefundAudit(
  adminClient: any,
  params: {
    transactionId: string;
    refundAmount: number;
    requestedBy: string;
    status: 'initiated' | 'approved' | 'rejected' | 'failed';
    reason: string;
    metadata?: Record<string, any>;
  }
): Promise<void> {
  await adminClient.from('refund_audit_log').insert({
    transaction_id: params.transactionId,
    refund_amount: params.refundAmount,
    requested_by: params.requestedBy,
    status: params.status,
    reason: params.reason,
    metadata: params.metadata || {},
  });
}

Deno.serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 1: Authenticate ──────────────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized — missing auth token' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const adminClient = createClient(supabaseUrl, supabaseServiceKey);

  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Invalid authentication token' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 2: Authorize ─────────────────────────────────────────────
  const auth = await isAuthorized(userClient, user.id);
  if (!auth.authorized) {
    await logRefundAudit(adminClient, {
      transactionId: 'unknown',
      refundAmount: 0,
      requestedBy: user.id,
      status: 'rejected',
      reason: `Unauthorized role: ${auth.role || 'unknown'}`,
    });
    return new Response(JSON.stringify({ error: 'Forbidden — insufficient permissions' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 3: Parse and validate request ─────────────────────────────
  let body: Record<string, any>;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const { transactionId, amount, reason: refundReason } = body;

  // Required fields
  if (!transactionId || !amount) {
    return new Response(JSON.stringify({ error: 'Missing required fields: transactionId, amount' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const refundAmount = parseFloat(amount);

  // Validate refund amount
  if (isNaN(refundAmount) || refundAmount <= 0) {
    await logRefundAudit(adminClient, {
      transactionId,
      refundAmount,
      requestedBy: user.id,
      status: 'rejected',
      reason: 'Invalid refund amount: must be a positive number',
    });
    return new Response(JSON.stringify({ error: 'Refund amount must be a positive number' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Prevent unreasonably large amounts
  if (refundAmount > 10000000) {
    await logRefundAudit(adminClient, {
      transactionId,
      refundAmount,
      requestedBy: user.id,
      status: 'rejected',
      reason: 'Refund amount exceeds maximum allowed (10,000,000 NGN)',
    });
    return new Response(JSON.stringify({ error: 'Refund amount exceeds maximum allowed' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 4: Verify original transaction exists ─────────────────────
  const { data: transaction, error: txError } = await adminClient
    .from('transactions')
    .select('id, amount, currency, status, flutterwave_transaction_id, school_id, user_id, refunded_amount')
    .eq('id', transactionId)
    .maybeSingle();

  if (txError || !transaction) {
    await logRefundAudit(adminClient, {
      transactionId,
      refundAmount,
      requestedBy: user.id,
      status: 'rejected',
      reason: 'Original transaction not found',
    });
    return new Response(JSON.stringify({ error: 'Original transaction not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 5: Verify transaction is refundable ───────────────────────
  if (transaction.status !== 'successful') {
    await logRefundAudit(adminClient, {
      transactionId,
      refundAmount,
      requestedBy: user.id,
      status: 'rejected',
      reason: `Transaction status is '${transaction.status}', not 'successful'`,
      metadata: { transactionStatus: transaction.status },
    });
    return new Response(JSON.stringify({ error: `Cannot refund a transaction with status '${transaction.status}'` }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // School admin can only refund transactions from their own school
  if (auth.role === 'school_admin' && auth.schoolId && transaction.school_id !== auth.schoolId) {
    await logRefundAudit(adminClient, {
      transactionId,
      refundAmount,
      requestedBy: user.id,
      status: 'rejected',
      reason: 'School admin attempted cross-school refund',
      metadata: { adminSchool: auth.schoolId, transactionSchool: transaction.school_id },
    });
    return new Response(JSON.stringify({ error: 'Cannot refund transactions from another school' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 6: Verify refund amount does not exceed original ──────────
  // PERFORMANCE FIX: Use atomic RPC to prevent race condition on refund amount.
  // Two concurrent refund requests could both read the same alreadyRefunded
  // value and both pass validation, resulting in over-refunding.
  // The process_refund_atomic() function uses SELECT FOR UPDATE to lock
  // the transaction row during validation, ensuring only one refund at a time.
  const { data: atomicResult, error: atomicError } = await adminClient
    .rpc('process_refund_atomic', {
      p_transaction_id: transactionId,
      p_refund_amount: refundAmount,
      p_requested_by: user.id,
      p_reason: refundReason || 'No reason provided',
    });

  if (atomicError || !atomicResult) {
    // Fallback to non-atomic validation if RPC not available yet
    // This maintains backward compatibility during migration
    const originalAmount = parseFloat(transaction.amount) || 0;
    const alreadyRefunded = parseFloat(transaction.refunded_amount) || 0;
    const remainingRefundable = originalAmount - alreadyRefunded;

    if (refundAmount > remainingRefundable) {
      await logRefundAudit(adminClient, {
        transactionId,
        refundAmount,
        requestedBy: user.id,
        status: 'rejected',
        reason: `Refund amount (${refundAmount}) exceeds remaining refundable (${remainingRefundable})`,
        metadata: { originalAmount, alreadyRefunded, remainingRefundable },
      });
      return new Response(JSON.stringify({
        error: `Refund amount exceeds remaining refundable amount. Original: ${originalAmount}, Already refunded: ${alreadyRefunded}, Remaining: ${remainingRefundable}`,
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ─── Step 7: Check for duplicate refund requests ────────────────────
    const { data: pendingRefunds } = await adminClient
    .from('refund_audit_log')
    .select('id, refund_amount, status, created_at')
    .eq('transaction_id', transactionId)
    .in('status', ['initiated', 'approved'])
    .order('created_at', { ascending: false })
    .limit(5);

  if (pendingRefunds && pendingRefunds.length > 0) {
    const totalPending = pendingRefunds.reduce((sum: number, r: any) => sum + parseFloat(r.refund_amount), 0);
    if (alreadyRefunded + totalPending + refundAmount > originalAmount) {
      await logRefundAudit(adminClient, {
        transactionId,
        refundAmount,
        requestedBy: user.id,
        status: 'rejected',
        reason: `Duplicate refund would exceed original amount. Pending: ${totalPending}`,
        metadata: { pendingRefunds: pendingRefunds.length, totalPending },
      });
      return new Response(JSON.stringify({
        error: `Duplicate refund detected. There are already pending refunds totaling ${totalPending} for this transaction.`,
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  }

  } // end of fallback block (non-atomic validation)

  // If atomic RPC succeeded, it handled the entire flow — return result
  if (atomicResult) {
    return new Response(JSON.stringify(atomicResult), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // ─── Step 8: Process refund via Flutterwave ─────────────────────────
  // (Only reached in fallback mode)
  const flwTxId = transaction.flutterwave_transaction_id;
  if (!flwTxId) {
    await logRefundAudit(adminClient, {
      transactionId,
      refundAmount,
      requestedBy: user.id,
      status: 'rejected',
      reason: 'No Flutterwave transaction ID found — cannot process refund via gateway',
    });
    return new Response(JSON.stringify({ error: 'Cannot process refund: missing payment gateway reference' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Log refund initiation
  await logRefundAudit(adminClient, {
    transactionId,
    refundAmount,
    requestedBy: user.id,
    status: 'initiated',
    reason: refundReason || 'No reason provided',
    metadata: { flwTxId },
  });

  // Call Flutterwave refund API with timeout to prevent indefinite hangs
  const flutterwaveSecretKey = Deno.env.get('FLUTTERWAVE_SECRET_KEY')!;
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30000); // 30s timeout
  try {
    const flwResponse = await fetch(
      `https://api.flutterwave.com/v3/transactions/${flwTxId}/refund`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${flutterwaveSecretKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ amount: refundAmount }),
        signal: controller.signal,
      }
    );

    const flwData = await flwResponse.json();

    if (flwData.status !== 'success') {
      await logRefundAudit(adminClient, {
        transactionId,
        refundAmount,
        requestedBy: user.id,
        status: 'failed',
        reason: `Flutterwave refund failed: ${flwData.message || 'Unknown error'}`,
        metadata: { flwResponse: flwData },
      });
      return new Response(JSON.stringify({
        error: 'Refund processing failed at payment gateway',
        details: flwData.message,
      }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ─── Step 9: Update transaction refunded amount ─────────────────
    const newRefundedAmount = alreadyRefunded + refundAmount;
    const updatePayload: Record<string, any> = {
      refunded_amount: newRefundedAmount,
    };

    // If fully refunded, update status
    if (newRefundedAmount >= originalAmount) {
      updatePayload.status = 'refunded';
    } else if (newRefundedAmount > 0) {
      updatePayload.status = 'partially_refunded';
    }

    await adminClient
      .from('transactions')
      .update(updatePayload)
      .eq('id', transactionId);

    // Log successful refund
    await logRefundAudit(adminClient, {
      transactionId,
      refundAmount,
      requestedBy: user.id,
      status: 'approved',
      reason: refundReason || 'Refund processed successfully',
      metadata: {
        flwRefundId: flwData.data?.id,
        newRefundedAmount,
        newStatus: updatePayload.status,
      },
    });

    return new Response(JSON.stringify({
      success: true,
      refundId: flwData.data?.id,
      transactionId,
      refundAmount,
      newRefundedAmount,
      transactionStatus: updatePayload.status || transaction.status,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err) {
    clearTimeout(timeoutId);
    const errorMessage = err instanceof Error ? err.message : String(err);
    const isTimeout = err instanceof DOMException && err.name === 'AbortError';
    await logRefundAudit(adminClient, {
      transactionId,
      refundAmount,
      requestedBy: user.id,
      status: 'failed',
      reason: isTimeout
        ? 'Flutterwave API timeout (30s)'
        : `Flutterwave API error: ${errorMessage}`,
    });
    return new Response(JSON.stringify({
      error: isTimeout
        ? 'Refund processing timed out. Please retry.'
        : 'Refund processing failed due to network error',
    }), {
      status: 502,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
