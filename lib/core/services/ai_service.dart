import '../models/meeting_model.dart';

/// Batas ukuran file audio yang diterima oleh Whisper (25 MB).
/// Dicek di client sebelum upload agar tidak membuang bandwidth.
const whisperMaxFileSizeBytes = 25 * 1024 * 1024;

/// Hasil transkripsi yang dikembalikan Edge Function `transcribe`.
typedef TranscriptionResult = ({List<TranscriptLine> lines, double durationSeconds});
