import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const adminEmails = new Set(
  (Deno.env.get("GAME_ADMIN_EMAILS") ?? "")
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean),
);
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const adminClient = createClient(supabaseUrl, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

function respond(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Cache-Control": "no-store", "Content-Type": "application/json" },
  });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return respond({ error: "Method not allowed." }, 405);
  }

  const authorization = request.headers.get("Authorization");
  const accessToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!accessToken) return respond({ error: "Sign in is required." }, 401);

  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser(accessToken);
  if (userError || !userData.user?.email) {
    return respond({ error: "Your session is invalid. Sign in again." }, 401);
  }

  const caller = userData.user;
  const callerEmail = caller.email.trim().toLowerCase();
  const isAdmin = adminEmails.has(callerEmail);

  let body: { action?: string; email?: string; password?: string };
  try {
    const parsed: unknown = await request.json();
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return respond({ error: "Request body must be a JSON object." }, 400);
    }
    body = parsed as { action?: string; email?: string; password?: string };
  } catch {
    return respond({ error: "Request body must be valid JSON." }, 400);
  }

  const { data: access, error: accessError } = await adminClient
    .from("game_access_allowlist")
    .select("email")
    .eq("email", callerEmail)
    .maybeSingle();
  if (accessError) {
    console.error("Allow-list lookup failed:", accessError);
    return respond({ error: "Could not verify game access." }, 500);
  }
  if (body.action === "check") return respond({ allowed: !!access, admin: isAdmin });
  if (!access) return respond({ error: "Your email is not on the game access list." }, 403);

  if (!isAdmin) return respond({ error: "Admin access is required." }, 403);

  if (body.action === "list") {
    const { data, error } = await adminClient
      .from("game_access_allowlist")
      .select("email,created_at")
      .order("email");
    if (error) {
      console.error("Allow-list read failed:", error);
      return respond({ error: "Could not load the allowed email list." }, 500);
    }
    return respond({ users: data ?? [] });
  }

  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return respond({ error: "Enter a valid email address." }, 400);
  }

  if (body.action === "remove") {
    if (email === callerEmail) {
      return respond({ error: "You cannot remove your own game access." }, 400);
    }
    const { error } = await adminClient
      .from("game_access_allowlist")
      .delete()
      .eq("email", email);
    if (error) {
      console.error("Allow-list removal failed:", error);
      return respond({ error: "Could not remove this email." }, 500);
    }
    return respond({ ok: true });
  }

  if (body.action !== "create") {
    return respond({ error: "Unknown action." }, 400);
  }
  if (typeof body.password !== "string" || body.password.length < 8) {
    return respond({ error: "Use a password with at least 8 characters." }, 400);
  }

  const { data, error } = await adminClient.auth.admin.createUser({
    email,
    password: body.password,
    email_confirm: true,
  });
  if (error || !data.user) {
    return respond({ error: error?.message ?? "Could not create the account." }, 400);
  }

  const { error: allowError } = await adminClient
    .from("game_access_allowlist")
    .upsert({ email, created_by: caller.id }, { onConflict: "email" });
  if (allowError) {
    const { error: rollbackError } = await adminClient.auth.admin.deleteUser(data.user.id);
    if (rollbackError) console.error("User creation rollback failed:", rollbackError);
    console.error("Allow-list insert failed:", allowError);
    return respond({ error: "Could not grant game access to the new account." }, 500);
  }

  return respond({ ok: true, email });
});
