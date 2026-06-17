import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const SPEAKER_CHANGE_GAP = 1.5; // detik — jeda minimum untuk dianggap ganti pembicara

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    // ── Verifikasi JWT pengguna ──────────────────────────────
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const { meeting_id } = await req.json() as { meeting_id: string };
    if (!meeting_id) return json({ error: "meeting_id wajib diisi" }, 400);

    // ── Ambil audio_path dari DB (pastikan milik user ini) ───
    const { data: meeting, error: dbError } = await supabase
      .from("meetings")
      .select("audio_path")
      .eq("id", meeting_id)
      .eq("user_id", user.id)
      .single();

    if (dbError || !meeting?.audio_path) {
      return json({ error: "Audio tidak ditemukan" }, 404);
    }

    // ── Download audio dari Supabase Storage (service role) ──
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: audioBlob, error: storageError } = await admin.storage
      .from("recordings")
      .download(meeting.audio_path);

    if (storageError || !audioBlob) {
      return json({ error: "Gagal mengunduh audio dari storage" }, 500);
    }

    // ── Kirim ke OpenAI Whisper ──────────────────────────────
    const filename = meeting.audio_path.split("/").pop() ?? "audio.m4a";
    const formData = new FormData();
    formData.append("file", audioBlob, filename);
    formData.append("model", "whisper-1");
    formData.append("language", "id");
    formData.append("response_format", "verbose_json");

    const whisperResp = await fetch("https://api.openai.com/v1/audio/transcriptions", {
      method: "POST",
      headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
      body: formData,
    });

    if (!whisperResp.ok) {
      const errText = await whisperResp.text();
      return json({ error: `Whisper error: ${errText}` }, 500);
    }

    const whisperData = await whisperResp.json();
    const segments: Array<{ start: number; end: number; text: string }> =
      whisperData.segments ?? [];
    const durationSeconds: number = whisperData.duration ?? 0;

    // ── Deteksi pergantian pembicara dari jeda antar segmen ──
    const lines: Array<{
      timestamp: string;
      speaker_id: string;
      speaker: string;
      text: string;
    }> = [];

    let speakerIdx = 0;
    let prevEnd: number | null = null;

    for (const seg of segments) {
      if (prevEnd !== null && seg.start - prevEnd > SPEAKER_CHANGE_GAP) {
        speakerIdx = (speakerIdx + 1) % 3;
      }
      prevEnd = seg.end;
      lines.push({
        timestamp: formatTime(Math.round(seg.start)),
        speaker_id: `S${speakerIdx + 1}`,
        speaker: `Suara ${speakerIdx + 1}`,
        text: seg.text.trim(),
      });
    }

    return json({ lines, duration_seconds: durationSeconds });
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

function formatTime(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  return `${pad(h)}:${pad(m)}:${pad(s)}`;
}

function pad(n: number): string {
  return String(n).padStart(2, "0");
}
