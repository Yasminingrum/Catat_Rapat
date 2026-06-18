import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Transkripsi live selama perekaman via OpenAI Realtime API (WebSocket).
///
/// API key diambil dari Supabase Edge Function `get-realtime-config` saat
/// pertama kali [connect] dipanggil — tidak perlu `--dart-define`.
class RealtimeTranscriptionService {
  static const _model = 'gpt-4o-realtime-preview';

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final _transcriptCtrl = StreamController<String>.broadcast();

  String? _cachedApiKey;
  bool _keyFetched = false;
  bool _connected = false;

  /// True sebelum connect dipanggil (optimistis), false setelah gagal.
  bool get isAvailable => !_keyFetched || _cachedApiKey != null;

  /// True jika WebSocket sedang terhubung ke OpenAI Realtime API.
  bool get isConnected => _connected;

  /// Stream potongan transkrip yang sudah final dari audio yang dikirim.
  Stream<String> get transcriptStream => _transcriptCtrl.stream;

  Future<String?> _fetchApiKey() async {
    if (_keyFetched) return _cachedApiKey;
    try {
      final res = await Supabase.instance.client.functions
          .invoke('get-realtime-config');
      if (res.status == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          _cachedApiKey = data['api_key'] as String?;
          if (_cachedApiKey != null && _cachedApiKey!.isEmpty) {
            _cachedApiKey = null;
          }
        }
      }
    } catch (_) {}
    _keyFetched = true;
    return _cachedApiKey;
  }

  Future<void> connect() async {
    final apiKey = await _fetchApiKey();
    if (apiKey == null) return;
    try {
      final channel = IOWebSocketChannel.connect(
        Uri.parse('wss://api.openai.com/v1/realtime?model=$_model'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'OpenAI-Beta': 'realtime=v1',
        },
      );

      await channel.ready;
      _channel = channel;

      _channel!.sink.add(jsonEncode({
        'type': 'session.update',
        'session': {
          'input_audio_format': 'pcm16',
          'input_audio_transcription': {'model': 'whisper-1'},
          'turn_detection': {'type': 'server_vad'},
        },
      }));
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
      _connected = true;
    } catch (_) {
      _channel = null;
      _connected = false;
    }
  }

  void _handleDisconnect() {
    _connected = false;
    _channel = null;
  }

  void _onMessage(dynamic message) {
    if (message is! String) return;
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'conversation.item.input_audio_transcription.completed') {
        final text = (data['transcript'] as String?)?.trim();
        if (text != null && text.isNotEmpty) _transcriptCtrl.add(text);
      } else if (type == 'error') {
        _connected = false;
      }
    } catch (_) {}
  }

  /// Kirim potongan audio PCM16 (mono, 24kHz) ke sesi realtime.
  void sendAudioChunk(Uint8List pcm16) {
    if (!_connected) return;
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode({
        'type': 'input_audio_buffer.append',
        'audio': base64Encode(pcm16),
      }));
    } catch (_) {
      _handleDisconnect();
    }
  }

  Future<void> disconnect() async {
    _connected = false;
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void dispose() {
    disconnect();
    _transcriptCtrl.close();
  }
}
