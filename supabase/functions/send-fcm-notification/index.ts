import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

type RequestPayload = {
  tokens: string[];
  title: string;
  body: string;
  type: string;
  targetScreen?: string;
  targetId?: string;
  notificationId?: string;
  notificationCollection?: string;
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function getAccessToken() {
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
  const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");
  const tokenUri = "https://oauth2.googleapis.com/token";

  if (!clientEmail || !privateKey) {
    throw new Error("Missing Firebase service account secrets");
  }

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: tokenUri,
    exp: now + 3600,
    iat: now,
  };

  const encoder = new TextEncoder();
  const toBase64Url = (input: Uint8Array | string) => {
    const raw = typeof input === "string" ? encoder.encode(input) : input;
    let binary = "";
    raw.forEach((b) => { binary += String.fromCharCode(b); });
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  };

  const unsignedToken = `${toBase64Url(JSON.stringify(header))}.${toBase64Url(JSON.stringify(payload))}`;

  const key = await crypto.subtle.importKey(
    "pkcs8", pemToArrayBuffer(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", key, encoder.encode(unsignedToken),
  );

  const jwt = `${unsignedToken}.${toBase64Url(new Uint8Array(signature))}`;

  const response = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Failed to get Google access token: ${errorText}`);
  }

  const data = await response.json();
  return data.access_token as string;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleanPem = pem
    .replace(/\\n/g, "\n")
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");
  const binary = atob(cleanPem);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) { bytes[i] = binary.charCodeAt(i); }
  return bytes.buffer;
}

async function sendToFcmToken(
  accessToken: string, projectId: string, token: string, payload: RequestPayload,
) {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const message = {
    message: {
      token,
      notification: { title: payload.title, body: payload.body },
      data: {
        type: payload.type, title: payload.title, body: payload.body,
        targetScreen: payload.targetScreen ?? "",
        targetId: payload.targetId ?? "",
        notificationId: payload.notificationId ?? "",
        notificationCollection: payload.notificationCollection ?? "",
      },
      android: { priority: "high", notification: { channel_id: "mix_high_importance_channel" } },
    },
  };

  const response = await fetch(url, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
    body: JSON.stringify(message),
  });

  const rawText = await response.text();
  return { ok: response.ok, status: response.status, raw: rawText, token };
}

serve(async (req) => {
  try {
    if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

    const authHeader = req.headers.get("Authorization");
    const functionSecret = Deno.env.get("MIX_FUNCTION_SECRET");
    if (!functionSecret) return jsonResponse({ error: "Missing function secret" }, 500);
    if (!authHeader || authHeader !== `Bearer ${functionSecret}`) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const body = (await req.json()) as RequestPayload;
    if (!body.tokens || !Array.isArray(body.tokens) || body.tokens.length == 0) {
      return jsonResponse({ error: "tokens is required" }, 400);
    }
    if (!body.title?.trim()) return jsonResponse({ error: "title is required" }, 400);
    if (!body.body?.trim()) return jsonResponse({ error: "body is required" }, 400);
    if (!body.type?.trim()) return jsonResponse({ error: "type is required" }, 400);

    const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
    if (!projectId) return jsonResponse({ error: "Missing FIREBASE_PROJECT_ID" }, 500);

    const accessToken = await getAccessToken();
    const uniqueTokens = [...new Set(body.tokens.map((t) => t.trim()).filter(Boolean))];

    const results = [];
    for (const token of uniqueTokens) {
      const sendResult = await sendToFcmToken(accessToken, projectId, token, body);
      results.push(sendResult);
    }

    const successCount = results.filter((r) => r.ok).length;
    const failureCount = results.length - successCount;

    return jsonResponse({ success: failureCount === 0, successCount, failureCount, results });
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : "Unknown error" }, 500);
  }
});
