/// Konfigurasi rahasia yang dibaca dari `--dart-define` saat build/run,
/// mis. `flutter run --dart-define=OPENAI_API_KEY=sk-...`.
abstract final class EnvConfig {
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
}
