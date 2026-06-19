// Supabase Edge Function: init-paystack-transaction
// Initializes a Paystack transaction securely using PAYSTACK_SECRET_KEY
// Returns authorization_url + reference for Flutter to open

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

type RequestPayload = {
  email: string;
  amountNaira: number;
  reference: string;
  currency?: string;
  metadata?: Record<string, unknown>;
  callback_url?: string;
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
    },
  });
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    const authHeader = req.headers.get("Authorization");
    const functionSecret = Deno.env.get("MIX_FUNCTION_SECRET");

    if (!functionSecret) {
      return jsonResponse({ error: "Missing function secret" }, 500);
    }

    if (!authHeader || authHeader !== `Bearer ${functionSecret}`) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const paystackSecret = Deno.env.get("PAYSTACK_SECRET_KEY");
    if (!paystackSecret) {
      return jsonResponse({ error: "Missing PAYSTACK_SECRET_KEY" }, 500);
    }

    const body = (await req.json()) as RequestPayload;

    if (!body.email?.trim()) {
      return jsonResponse({ error: "email is required" }, 400);
    }

    if (!(body.amountNaira > 0)) {
      return jsonResponse({ error: "amountNaira must be greater than 0" }, 400);
    }

    if (!body.reference?.trim()) {
      return jsonResponse({ error: "reference is required" }, 400);
    }

    const payload = {
      email: body.email.trim(),
      amount: Math.round(body.amountNaira * 100),
      reference: body.reference.trim(),
      currency: body.currency ?? "NGN",
      metadata: body.metadata ?? {},
      callback_url: body.callback_url ?? null,
    };

    const response = await fetch("https://api.paystack.co/transaction/initialize", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${paystackSecret}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const raw = await response.text();

    if (!response.ok) {
      return jsonResponse(
        {
          error: "Paystack initialize failed",
          raw,
        },
        response.status,
      );
    }

    const decoded = JSON.parse(raw);

    return jsonResponse({
      success: true,
      message: decoded.message,
      data: decoded.data,
    });
  } catch (error) {
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : "Unknown error",
      },
      500,
    );
  }
});
