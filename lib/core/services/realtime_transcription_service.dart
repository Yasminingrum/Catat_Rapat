import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/env_config.dart';

/// Transkripsi live selama perekaman via OpenAI Realtime API (WebSocket).
///
/// Membutuhkan `OPENAI_API_KEY` (lihat [EnvConfig]). Jika tidak diset,
/// [isAvailable] bernilai false dan transkripsi live dinonaktifkan.
class RealtimeTranscriptionService {
  static const _model = 'gpt-4o-realtime-preview';

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final _transcriptCtrl = StreamController<String>.broadcast();

  bool get isAvailable => EnvConfig.openAiApiKey.isNotEmpty;

  /// Stream potongan transkrip yang sudah final dari audio yang dikirim.
  Stream<String> get transcriptStream => _transcriptCtrl.stream;

  Future<void> connect() async {
    if (!isAvailable) return;
    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse('wss://api.openai.com/v1/realtime?model=$_model'),
        headers: {
          'Authorization': 'Bearer ${EnvConfig.openAiApiKey}',
          'OpenAI-Beta': 'realtime=v1',
        },
      );
      _channel!.sink.add(jsonEncode({
        'type': 'session.update',
        'session': {
          'input_audio_format': 'pcm16',
          'input_audio_transcription': {'model': 'whisper-1'},
          'turn_detection': {'type': 'server_vad'},
        },
      }));
      _sub = _channel!.stream.listen(_onMessage, onError: (_) {}, cancelOnError: false);
    } catch (_) {
      _channel = null;
    }
  }

  void _onMessage(dynamic message) {
    if (message is! String) return;
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['type'] == 'conversation.item.input_audio_transcription.completed') {
        final text = (data['transcript'] as String?)?.trim();
        if (text != null && text.isNotEmpty) _transcriptCtrl.add(text);
      }
    } catch (_) {}
  }

  /// Kirim potongan audio PCM16 (mono, 24kHz) ke sesi realtime.
  void sendAudioChunk(Uint8List pcm16) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode({
      'type': 'input_audio_buffer.append',
      'audio': base64Encode(pcm16),
    }));
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _transcriptCtrl.close();
  }
}
