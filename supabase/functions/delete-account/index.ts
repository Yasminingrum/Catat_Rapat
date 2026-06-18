import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    // Client dengan anon key — hanya untuk autentikasi user yang request.
    const anonClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization") ?? "" },
        },
      }
    );

    const {
      data: { user },
      error: authErr,
    } = await anonClient.auth.getUser();
    if (authErr || !user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const uid = user.id;

    // Client dengan service_role key — bypass RLS untuk hapus semua data.
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Ambil semua meeting milik user.
    const { data: meetings } = await admin
      .from("meetings")
      .select("id, audio_path")
      .eq("user_id", uid);

    const meetingIds = (meetings ?? []).map((m: { id: string }) => m.id);

    if (meetingIds.length > 0) {
      await admin.from("notulas").delete().in("meeting_id", meetingIds);
      await admin
        .from("transcript_lines")
        .delete()
        .in("meeting_id", meetingIds);
      await admin.from("participants").delete().in("meeting_id", meetingIds);
      await admin.from("meetings").delete().eq("user_id", uid);
    }

    // Hapus file audio di storage.
    const audioPaths = (meetings ?? [])
      .map((m: { audio_path: string | null }) => m.audio_path)
      .filter(Boolean) as string[];
    if (audioPaths.length > 0) {
      await admin.storage.from("recordings").remove(audioPaths);
    }

    // Tandai profil sebagai dihapus, tapi JANGAN hapus row-nya.
    // Data plan & token_used dipertahankan agar user tidak bisa abuse
    // free tier dengan hapus-daftar ulang.
    await admin
      .from("profiles")
      .update({ name: "[Akun Dihapus]", deleted_at: new Date().toISOString() })
      .eq("id", uid);

    // Hapus auth user — user tidak bisa login lagi kecuali daftar ulang.
    await admin.auth.admin.deleteUser(uid);

    return json({ success: true });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
