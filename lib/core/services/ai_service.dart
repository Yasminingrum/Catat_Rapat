import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/meeting_model.dart';

/// Hasil transkripsi: baris transkrip (dengan speaker hasil deteksi
/// berbasis jeda antar segmen) beserta total durasi audio.
typedef TranscriptionResult = ({List<TranscriptLine> lines, double durationSeconds});

/// Batas ukuran file untuk transkripsi Whisper (OpenAI: 25 MB).
const whisperMaxFileSizeBytes = 25 * 1024 * 1024;

/// Jeda minimum antar segmen (detik) untuk dianggap pergantian pembicara.
const _speakerChangeGapSeconds = 1.5;

/// Service untuk memanggil OpenAI Whisper (transkripsi) + GPT (notula).
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 5),
  ));

  // ─── Transkripsi (OpenAI Whisper) ─────────────────────────

  Future<TranscriptionResult> transcribeAudio({
    required String audioPath,
    required String openAiKey,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(audioPath,
          filename: audioPath.split(RegExp(r'[\\/]')).last),
      'model': 'whisper-1',
      'language': 'id',
      'response_format': 'verbose_json',
    });

    final resp = await _dio.post(
      'https://api.openai.com/v1/audio/transcriptions',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $openAiKey'}),
    );

    // Parse segments menjadi TranscriptLine, deteksi pergantian speaker
    // dari jeda antar segmen (heuristik sederhana, bergilir S1/S2/S3).
    final segments = (resp.data['segments'] as List<dynamic>? ?? []);
    final lines = <TranscriptLine>[];
    var speakerIdx = 0;
    double? prevEnd;
    for (final entry in segments) {
      final seg = entry as Map<String, dynamic>;
      final start = (seg['start'] as num).toDouble();
      final end = (seg['end'] as num).toDouble();
      if (prevEnd != null && start - prevEnd > _speakerChangeGapSeconds) {
        speakerIdx = (speakerIdx + 1) % 3;
      }
      prevEnd = end;
      lines.add(TranscriptLine(
        timestamp: _formatTime(start.round()),
        speakerId: 'S${speakerIdx + 1}',
        speaker: 'Suara ${speakerIdx + 1}',
        text: (seg['text'] as String).trim(),
      ));
    }

    final duration = (resp.data['duration'] as num?)?.toDouble() ?? prevEnd ?? 0;
    return (lines: lines, durationSeconds: duration);
  }

  // ─── Generate Notula (OpenAI GPT) ──────────────────────────

  Future<Notula> generateNotula({
    required List<TranscriptLine> transcript,
    required String openAiKey,
  }) async {
    final transcriptText = transcript
        .map((l) => '[${l.timestamp}] ${l.speaker}: ${l.text}')
        .join('\n');

    final prompt = '''
Kamu adalah AI asisten notulis rapat profesional.
Analisis transkripsi rapat berikut dalam Bahasa Indonesia dan buat notula terstruktur.

TRANSKRIPSI:
$transcriptText

INSTRUKSI:
Kembalikan HANYA JSON valid dengan format:
{
  "ringkasan": "ringkasan naratif 2-4 kalimat",
  "keputusan": [{"id": 1, "text": "keputusan pertama"}, ...],
  "action_items": [{"id": 1, "text": "deskripsi tugas", "assignee": "nama PIC atau kosong", "deadline": "tanggal atau kosong", "status": "pending"}, ...]
}
''';

    final resp = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      data: {
        'model': 'gpt-4o-mini',
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content': 'Kamu adalah AI asisten notulis rapat profesional. '
                'Selalu balas dengan JSON valid sesuai format yang diminta.',
          },
          {'role': 'user', 'content': prompt},
        ],
      },
      options: Options(headers: {
        'Authorization': 'Bearer $openAiKey',
        'Content-Type': 'application/json',
      }),
    );

    final text = resp.data['choices'][0]['message']['content'] as String;
    final json = _parseJson(text);
    return Notula.fromJson(json);
  }

  Map<String, dynamic> _parseJson(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return {
        'ringkasan': s.isNotEmpty ? s : '',
        'keputusan': [],
        'action_items': [],
      };
    }
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }
}