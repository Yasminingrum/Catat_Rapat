/// Konfigurasi yang dibaca dari `--dart-define` saat build/run.
///
/// OPENAI_API_KEY: hanya dibutuhkan untuk fitur transkripsi live (WebSocket
/// Realtime API). Transkripsi batch dan generate notula sudah diproksikan
/// melalui Supabase Edge Functions dan tidak memerlukan key ini.
abstract final class EnvConfig {
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
}
