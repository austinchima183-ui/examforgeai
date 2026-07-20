// ============================================================================
// ExamForge AI — Marketplace Secure Download Edge Function
// ============================================================================
// Generates time-limited signed URLs for marketplace product downloads.
// All downloads MUST go through this function — never expose Storage
// URLs directly to the client.
//
// Flow:
//   1. Client requests download with a purchase ID
//   2. Function validates the purchase (completed, belongs to user)
//   3. Function generates a download token via SQL function
//   4. Function creates a signed URL using the token
//   5. Client receives the signed URL and downloads the file
//   6. Each download is audited and counted
// ============================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // Create client with user's auth token for RLS
  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  // Create admin client for privileged operations
  const adminClient = createClient(supabaseUrl, supabaseServiceKey);

  // Verify the user
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Invalid token' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const body = await req.json();
    const { purchaseId, productId } = body;

    if (!purchaseId || !productId) {
      return new Response(JSON.stringify({ error: 'Missing purchaseId or productId' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ─── Verify the purchase belongs to this user ────────────────────────
    const { data: purchase, error: purchaseError } = await adminClient
      .from('marketplace_purchases')
      .select('id, buyer_id, product_id, status, seller_id')
      .eq('id', purchaseId)
      .eq('buyer_id', user.id)
      .eq('status', 'completed')
      .maybeSingle();

    if (purchaseError || !purchase) {
      return new Response(JSON.stringify({ error: 'Purchase not found or not completed' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (purchase.product_id !== productId) {
      return new Response(JSON.stringify({ error: 'Product does not match purchase' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ─── Get product file info ───────────────────────────────────────────
    const { data: product, error: productError } = await adminClient
      .from('marketplace_products')
      .select('id, file_storage_path, file_name, seller_id, status')
      .eq('id', productId)
      .eq('status', 'published')
      .maybeSingle();

    if (productError || !product || !product.file_storage_path) {
      return new Response(JSON.stringify({ error: 'Product not available' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ─── Generate download token ─────────────────────────────────────────
    const { data: tokenResult, error: tokenError } = await adminClient.rpc(
      'generate_download_token',
      {
        p_purchase_id: purchaseId,
        p_product_id: productId,
        p_buyer_id: user.id,
        p_seller_id: purchase.seller_id || product.seller_id,
        p_file_path: product.file_storage_path,
        p_file_name: product.file_name || 'download',
        p_max_downloads: 5,
        p_expiry_hours: 24,
      }
    );

    if (tokenError || !tokenResult) {
      console.error('Token generation failed:', tokenError);
      return new Response(JSON.stringify({ error: 'Failed to generate download token' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ─── Create signed URL for the file ──────────────────────────────────
    const { data: signedUrlData, error: signedUrlError } = await adminClient.storage
      .from('marketplace-products')
      .createSignedUrl(product.file_storage_path, 3600, {
        download: true,
        transform: undefined,
      });

    if (signedUrlError || !signedUrlData) {
      console.error('Signed URL creation failed:', signedUrlError);
      return new Response(JSON.stringify({ error: 'Failed to create download URL' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ─── Return download info ────────────────────────────────────────────
    return new Response(JSON.stringify({
      downloadUrl: signedUrlData.signedUrl,
      token: tokenResult,
      fileName: product.file_name || 'download',
      expiresIn: 3600, // 1 hour for signed URL
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err) {
    console.error('Download function error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
