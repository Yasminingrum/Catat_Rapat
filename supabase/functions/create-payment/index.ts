import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MIDTRANS_SERVER_KEY = Deno.env.get("MIDTRANS_SERVER_KEY")!;
const IS_PRODUCTION = Deno.env.get("MIDTRANS_IS_PRODUCTION") === "true";
const SNAP_URL = IS_PRODUCTION
  ? "https://app.midtrans.com/snap/v1/transactions"
  : "https://app.sandbox.midtrans.com/snap/v1/transactions";

// Harga dalam Rupiah
const PRICES: Record<string, number> = {
  pro_monthly: 199000,
  pro_yearly: 1999000,
  platinum_monthly: 549000,
  platinum_yearly: 5499000,
};

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS });
  }

  try {
    // Verifikasi JWT pengguna dari header Authorization
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...CORS, "Content-Type": "application/json" },
      });
    }

    const { plan, billing_cycle } = await req.json() as {
      plan: "pro" | "platinum";
      billing_cycle: "monthly" | "yearly";
    };

    const priceKey = `${plan}_${billing_cycle}`;
    const amount = PRICES[priceKey];
    if (!amount) {
      return new Response(JSON.stringify({ error: "Paket tidak valid" }), {
        status: 400, headers: { ...CORS, "Content-Type": "application/json" },
      });
    }

    // Order ID unik: prefix + 8 char user id + timestamp
    const orderId = `cr-${user.id.substring(0, 8)}-${Date.now()}`;
    const planLabel = plan === "pro" ? "Pro" : "Platinum";
    const cycleLabel = billing_cycle === "monthly" ? "Bulanan" : "Tahunan";
    const auth = btoa(`${MIDTRANS_SERVER_KEY}:`);

    const midtransRes = await fetch(SNAP_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${auth}`,
      },
      body: JSON.stringify({
        transaction_details: { order_id: orderId, gross_amount: amount },
        customer_details: {
          email: user.email,
          first_name: user.user_metadata?.name ?? "Pengguna",
        },
        item_details: [{
          id: priceKey,
          price: amount,
          quantity: 1,
          name: `CatatRapat ${planLabel} - ${cycleLabel}`,
        }],
        // URL yang akan dideteksi oleh WebView Flutter setelah pembayaran
        callbacks: {
          finish: "https://catatrapat.app/payment/finish",
          error: "https://catatrapat.app/payment/error",
          pending: "https://catatrapat.app/payment/pending",
        },
      }),
    });

    const result = await midtransRes.json();

    if (!midtransRes.ok) {
      const msg = result.error_messages?.[0] ?? "Gagal membuat transaksi";
      return new Response(JSON.stringify({ error: msg }), {
        status: 500, headers: { ...CORS, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ token: result.token }), {
      headers: { ...CORS, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500, headers: { ...CORS, "Content-Type": "application/json" },
    });
  }
});
