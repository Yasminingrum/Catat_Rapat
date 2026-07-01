import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const SPEAKER_CHANGE_GAP = 1.5;
// 24MB — aman di bawah batas 25MB Whisper, dengan ruang untuk header HTTP
const MAX_WHISPER_BYTES = 24 * 1024 * 1024;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type Segment = { start: number; end: number; text: string };

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) return json({ error: "Unauthorized" }, 401);

    const { meeting_id } = await req.json() as { meeting_id: string };
    if (!meeting_id) return json({ error: "meeting_id wajib diisi" }, 400);

    const { data: meeting, error: dbError } = await supabase
      .from("meetings")
      .select("audio_path")
      .eq("id", meeting_id)
      .eq("user_id", user.id)
      .single();

    if (dbError || !meeting?.audio_path) return json({ error: "Audio tidak ditemukan" }, 404);

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: audioBlob, error: storageError } = await admin.storage
      .from("recordings")
      .download(meeting.audio_path);

    if (storageError || !audioBlob) return json({ error: "Gagal mengunduh audio dari storage" }, 500);

    const filename = meeting.audio_path.split("/").pop() ?? "audio.wav";
    const isWav = filename.toLowerCase().endsWith(".wav");

    let allSegments: Segment[] = [];
    let totalDuration = 0;

    if (isWav && audioBlob.size > MAX_WHISPER_BYTES) {
      // File terlalu besar — pecah WAV menjadi potongan ≤24MB
      const chunks = await splitWav(audioBlob);
      for (const { blob, offsetSeconds } of chunks) {
        const segments = await transcribeChunk(blob, filename, offsetSeconds);
        allSegments = allSegments.concat(segments);
      }
      if (allSegments.length > 0) {
        totalDuration = allSegments[allSegments.length - 1].end;
      }
    } else {
      // File cukup kecil — kirim langsung ke Whisper
      const result = await transcribeDirect(audioBlob, filename);
      allSegments = result.segments;
      totalDuration = result.duration;
    }

    return json({ lines: buildLines(allSegments), duration_seconds: totalDuration });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

// ── WAV chunking ──────────────────────────────────────────────────────────────

async function splitWav(blob: Blob): Promise<Array<{ blob: Blob; offsetSeconds: number }>> {
  const buf = await blob.arrayBuffer();
  const view = new DataView(buf);

  // Parse header RIFF/WAV untuk mendapatkan parameter audio
  let offset = 12; // lewati "RIFF????WAVE"
  let sampleRate = 16000;
  let numChannels = 1;
  let bitsPerSample = 16;
  let dataOffset = 0;
  let dataSize = 0;

  while (offset < buf.byteLength - 8) {
    const id = readFourCC(view, offset);
    const size = view.getUint32(offset + 4, true);
    if (id === "fmt ") {
      numChannels   = view.getUint16(offset + 10, true);
      sampleRate    = view.getUint32(offset + 12, true);
      bitsPerSample = view.getUint16(offset + 22, true);
    } else if (id === "data") {
      dataOffset = offset + 8;
      dataSize   = Math.min(size, buf.byteLength - dataOffset);
      break;
    }
    offset += 8 + size + (size % 2); // chunk WAV selalu word-aligned
  }

  if (dataOffset === 0) throw new Error("Format WAV tidak valid: chunk data tidak ditemukan");

  const blockAlign    = numChannels * (bitsPerSample / 8);
  const bytesPerSecond = sampleRate * blockAlign;
  // Batas data per potongan, dibulatkan ke batas blok PCM
  const maxDataBytes  = Math.floor((MAX_WHISPER_BYTES - 44) / blockAlign) * blockAlign;

  const chunks: Array<{ blob: Blob; offsetSeconds: number }> = [];
  let pos = 0;

  while (pos < dataSize) {
    const chunkDataSize = Math.min(maxDataBytes, dataSize - pos);
    const header    = buildWavHeader(chunkDataSize, sampleRate, numChannels, bitsPerSample);
    const chunkData = new Uint8Array(buf, dataOffset + pos, chunkDataSize);
    chunks.push({
      blob: new Blob([header, chunkData], { type: "audio/wav" }),
      offsetSeconds: pos / bytesPerSecond,
    });
    pos += chunkDataSize;
  }

  return chunks;
}

function buildWavHeader(
  dataBytes: number,
  sampleRate: number,
  numChannels: number,
  bitsPerSample: number,
): Uint8Array {
  const buf       = new ArrayBuffer(44);
  const v         = new DataView(buf);
  const byteRate  = sampleRate * numChannels * bitsPerSample / 8;
  const blockAlign = numChannels * bitsPerSample / 8;

  writeFourCC(v, 0, "RIFF");
  v.setUint32(4, 36 + dataBytes, true);
  writeFourCC(v, 8, "WAVE");
  writeFourCC(v, 12, "fmt ");
  v.setUint32(16, 16, true);
  v.setUint16(20, 1, true);          // PCM
  v.setUint16(22, numChannels, true);
  v.setUint32(24, sampleRate, true);
  v.setUint32(28, byteRate, true);
  v.setUint16(32, blockAlign, true);
  v.setUint16(34, bitsPerSample, true);
  writeFourCC(v, 36, "data");
  v.setUint32(40, dataBytes, true);

  return new Uint8Array(buf);
}

function readFourCC(v: DataView, offset: number): string {
  return String.fromCharCode(
    v.getUint8(offset), v.getUint8(offset + 1),
    v.getUint8(offset + 2), v.getUint8(offset + 3),
  );
}

function writeFourCC(v: DataView, offset: number, s: string) {
  for (let i = 0; i < 4; i++) v.setUint8(offset + i, s.charCodeAt(i));
}

// ── Whisper API calls ─────────────────────────────────────────────────────────

async function transcribeChunk(
  blob: Blob,
  filename: string,
  offsetSeconds: number,
): Promise<Segment[]> {
  const formData = new FormData();
  formData.append("file", blob, filename);
  formData.append("model", "whisper-1");
  formData.append("language", "id");
  formData.append("response_format", "verbose_json");

  const resp = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
    body: formData,
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Whisper error: ${errText}`);
  }

  const data = await resp.json();
  // Geser timestamp tiap segmen sesuai posisi potongan dalam rekaman asli
  return ((data.segments ?? []) as Segment[]).map((seg) => ({
    start: seg.start + offsetSeconds,
    end:   seg.end   + offsetSeconds,
    text:  seg.text,
  }));
}

async function transcribeDirect(
  blob: Blob,
  filename: string,
): Promise<{ segments: Segment[]; duration: number }> {
  const formData = new FormData();
  formData.append("file", blob, filename);
  formData.append("model", "whisper-1");
  formData.append("language", "id");
  formData.append("response_format", "verbose_json");

  const resp = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
    body: formData,
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Whisper error: ${errText}`);
  }

  const data = await resp.json();
  return {
    segments: (data.segments ?? []) as Segment[],
    duration: (data.duration as number) ?? 0,
  };
}

// ── Speaker detection ─────────────────────────────────────────────────────────

function buildLines(segments: Segment[]) {
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
      timestamp:  formatTime(Math.round(seg.start)),
      speaker_id: `S${speakerIdx + 1}`,
      speaker:    `Suara ${speakerIdx + 1}`,
      text:       seg.text.trim(),
    });
  }

  return lines;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
