import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/realtime_transcription_service.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/utils/wav_writer.dart';

const _sampleRate = 24000;

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key, required this.title, this.agenda});

  final String title;
  final String? agenda;

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  final _recorder = AudioRecorder();
  final _liveTranscription = RealtimeTranscriptionService();
  WavWriter? _wavWriter;
  String? _recordingPath;
  StreamSubscription<Uint8List>? _audioStreamSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<String>? _transcriptSub;

  // Timer
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPaused = false;

  // Audio quality (dari amplitude mikrofon, 0-100%)
  int _audioQuality = 0;

  // Waveform bars
  List<double> _waveHeights = List.filled(28, 8.0);

  // Transkrip live (diisi dari RealtimeTranscriptionService)
  final List<_TranscriptLine> _transcriptLines = [];
  bool _showTyping = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Pulse animation untuk REC indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _startRecording();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        SnackbarUtil.showError(context, 'Izin mikrofon diperlukan untuk merekam');
        context.pop();
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    _recordingPath = path;
    _wavWriter = WavWriter(path, sampleRate: _sampleRate, numChannels: 1);
    await _wavWriter!.open();

    // Transkripsi live via OpenAI Realtime API (jika OPENAI_API_KEY tersedia)
    if (_liveTranscription.isAvailable) {
      await _liveTranscription.connect();
      _transcriptSub = _liveTranscription.transcriptStream.listen((text) {
        if (!mounted) return;
        setState(() {
          _transcriptLines.add(_TranscriptLine(speaker: 'Live', speakerIdx: 0, text: text));
        });
      });
    }

    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: _sampleRate,
      numChannels: 1,
    ));
    _audioStreamSub = stream.listen((chunk) {
      if (_isPaused) return;
      _wavWriter?.writeChunk(chunk);
      _liveTranscription.sendAudioChunk(chunk);
    });

    // Timer rekam
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) setState(() => _elapsedSeconds++);
    });

    // Kualitas audio & waveform dari amplitude mikrofon sesungguhnya
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((amp) {
      if (_isPaused) return;
      const minDb = -60.0, maxDb = -10.0;
      final norm = ((amp.current - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
      setState(() {
        _audioQuality = (norm * 100).round().clamp(0, 100);
        _waveHeights = [..._waveHeights.skip(1), 6.0 + norm * 30.0];
      });
    });
  }

  Future<void> _togglePause() async {
    final pausing = !_isPaused;
    if (pausing) {
      await _recorder.pause();
    } else {
      await _recorder.resume();
    }
    setState(() {
      _isPaused = pausing;
      _showTyping = !pausing && _liveTranscription.isAvailable;
      if (pausing) _waveHeights = List.filled(28, 8.0);
    });
    if (_isPaused) {
      _pulseController.stop();
    } else {
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _done() async {
    await _recorder.stop();
    await _audioStreamSub?.cancel();
    await _wavWriter?.close();
    await _liveTranscription.disconnect();
    _stopAll();
    if (!mounted) return;
    context.pushReplacement('/processing', extra: {
      'title': widget.title,
      'agenda': widget.agenda,
      'filePath': _recordingPath,
      'durationSeconds': _elapsedSeconds,
    });
  }

  void _stopAll() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _transcriptSub?.cancel();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _stopAll();
    _audioStreamSub?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    _liveTranscription.dispose();
    super.dispose();
  }

  String _formatTime(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  AudioQualityLevel get _qualityLevel {
    if (_audioQuality >= 70) return AudioQualityLevel.good;
    if (_audioQuality >= 40) return AudioQualityLevel.medium;
    return AudioQualityLevel.poor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────────────
            _RecordingHeader(
              title: widget.title,
              isPaused: _isPaused,
              pulseController: _pulseController,
              onBack: () {
                // Konfirmasi sebelum keluar
                showDialog(
                  context: context,
                  builder: (_) => _ConfirmExitDialog(
                    onConfirm: () async {
                      await _recorder.cancel();
                      await _audioStreamSub?.cancel();
                      await _wavWriter?.close();
                      await _liveTranscription.disconnect();
                      _stopAll();
                      if (context.mounted) {
                        context.pop();
                        context.pop();
                      }
                    },
                  ),
                );
              },
            ),

            // ─── Scrollable Content ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    // Audio quality
                    _AudioQualityCard(
                      quality: _audioQuality,
                      level: _qualityLevel,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Timer
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 2,
                        fontFeatures: [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // REC / DIJEDA status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isPaused
                                  ? AppColors.warning
                                  : AppColors.error.withValues(
                                  alpha: 0.5 + _pulseController.value * 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPaused ? 'DIJEDA' : 'REC',
                          style: AppTextStyles.bodyMd(
                            c: _isPaused
                                ? AppColors.warning
                                : AppColors.error,
                            w: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Waveform
                    _WaveformVisualizer(
                      heights: _waveHeights,
                      isPaused: _isPaused,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Live transcript (PBI11)
                    _LiveTranscriptCard(
                      lines: _transcriptLines,
                      showTyping: _showTyping && !_isPaused,
                      isLive: _liveTranscription.isAvailable,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // ─── Controls ────────────────────────────────────────
            _RecordingControls(
              isPaused: _isPaused,
              onPause: _togglePause,
              onDone: _done,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _RecordingHeader extends StatelessWidget {
  const _RecordingHeader({
    required this.title,
    required this.isPaused,
    required this.pulseController,
    required this.onBack,
  });

  final String title;
  final bool isPaused;
  final AnimationController pulseController;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderMedium),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.displayXs(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Audio Quality ────────────────────────────────────────────────────────────

enum AudioQualityLevel { good, medium, poor }

class _AudioQualityCard extends StatelessWidget {
  const _AudioQualityCard({required this.quality, required this.level});

  final int quality;
  final AudioQualityLevel level;

  Color get _color {
    switch (level) {
      case AudioQualityLevel.good: return AppColors.success;
      case AudioQualityLevel.medium: return AppColors.warning;
      case AudioQualityLevel.poor: return AppColors.error;
    }
  }

  Color get _bgColor {
    switch (level) {
      case AudioQualityLevel.good: return AppColors.successLight;
      case AudioQualityLevel.medium: return AppColors.warningLight;
      case AudioQualityLevel.poor: return AppColors.errorLight;
    }
  }

  String get _label {
    switch (level) {
      case AudioQualityLevel.good: return 'Bagus';
      case AudioQualityLevel.medium: return 'Sedang';
      case AudioQualityLevel.poor: return 'Lemah';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.sensors_rounded, size: 14,
                  color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Kualitas Audio',
                  style: AppTextStyles.bodySm(
                      c: AppColors.textSecondary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: _bgColor, borderRadius: AppRadius.full),
                child: Text(_label,
                    style: AppTextStyles.caption(
                        c: _color, w: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Text('$quality%',
                  style: AppTextStyles.caption(
                      c: AppColors.textTertiary,
                      w: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          // 5 quality bars
          Row(
            children: List.generate(5, (i) {
              Color barColor;
              if (i < 2) {
                barColor = AppColors.error;
              } else if (i == 2) {
                barColor = AppColors.warning;
              } else {
                barColor = AppColors.success;
              }

              final activeCount = (quality / 20).ceil();
              final isActive = i < activeCount;

              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? barColor : AppColors.divider,
                    borderRadius: AppRadius.full,
                  ),
                ),
              );
            }),
          ),
          if (level == AudioQualityLevel.poor) ...[
            const SizedBox(height: 8),
            Text('💡 Dekati mikrofon atau kurangi noise di ruangan',
                style: AppTextStyles.bodySm(c: AppColors.warning)),
          ],
        ],
      ),
    );
  }
}

// ─── Waveform ─────────────────────────────────────────────────────────────────

class _WaveformVisualizer extends StatelessWidget {
  const _WaveformVisualizer({required this.heights, required this.isPaused});

  final List<double> heights;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(heights.length, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 4,
            height: isPaused ? 8 : heights[i],
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: isPaused ? AppColors.divider : AppColors.primary,
              borderRadius: AppRadius.full,
            ),
          );
        }),
      ),
    );
  }
}

// ─── Live Transcript ──────────────────────────────────────────────────────────

class _TranscriptLine {
  const _TranscriptLine({
    required this.speaker,
    required this.speakerIdx,
    required this.text,
  });
  final String speaker;
  final int speakerIdx;
  final String text;
}

class _LiveTranscriptCard extends StatelessWidget {
  const _LiveTranscriptCard({
    required this.lines,
    required this.showTyping,
    required this.isLive,
  });

  final List<_TranscriptLine> lines;
  final bool showTyping;
  final bool isLive;

  static const _speakerColors = [
    AppColors.speaker1, AppColors.speaker2, AppColors.speaker3
  ];
  static const _speakerBgColors = [
    AppColors.speaker1Bg, AppColors.speaker2Bg, AppColors.speaker3Bg
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Transkripsi Berjalan',
                  style: AppTextStyles.displayXs(w: FontWeight.w700)),
              const Spacer(),
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLive ? AppColors.success : AppColors.textTertiary),
              ),
              const SizedBox(width: 4),
              Text(isLive ? 'Aktif' : 'Nonaktif',
                  style: AppTextStyles.bodySm(
                      c: isLive ? AppColors.success : AppColors.textTertiary,
                      w: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          if (lines.isEmpty)
            Text(
              isLive
                  ? 'Menunggu suara untuk ditranskripsi...'
                  : 'Transkripsi live tidak tersedia. Notula tetap akan dibuat setelah rekaman selesai.',
              style: AppTextStyles.bodySm(c: AppColors.textTertiary),
            )
          else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: lines.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final line = lines[i];
                final idx = line.speakerIdx.clamp(0, 2);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _speakerBgColors[idx],
                      ),
                      child: Center(
                        child: Text(
                          '${line.speakerIdx + 1}',
                          style: AppTextStyles.caption(
                              c: _speakerColors[idx],
                              w: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.speaker,
                              style: AppTextStyles.caption(
                                  c: _speakerColors[idx],
                                  w: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(line.text,
                              style: AppTextStyles.bodyMd(
                                  c: const Color(0xFF334155))),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          if (showTyping) ...[
            const SizedBox(height: AppSpacing.md),
            _TypingIndicator(),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        children: List.generate(3, (i) {
          final delay = i * 0.3;
          final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final opacity = (math.sin(t * math.pi)).clamp(0.3, 1.0);
          return Container(
            margin: const EdgeInsets.only(right: 4),
            width: 7, height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textTertiary.withValues(alpha: opacity),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Controls ─────────────────────────────────────────────────────────────────

class _RecordingControls extends StatelessWidget {
  const _RecordingControls({
    required this.isPaused,
    required this.onPause,
    required this.onDone,
  });

  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pause / Play
              GestureDetector(
                onTap: onPause,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderMedium),
                  ),
                  child: Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 28, color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Done (checkmark)
              GestureDetector(
                onTap: onDone,
                child: Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.buttonSuccess,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 28, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Jeda atau selesai untuk tambah peserta',
            style: AppTextStyles.caption(c: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Confirm Exit Dialog ──────────────────────────────────────────────────────

class _ConfirmExitDialog extends StatelessWidget {
  const _ConfirmExitDialog({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      title: Text('Hentikan rekaman?',
          style: AppTextStyles.displayXs()),
      content: Text(
          'Rekaman akan dihentikan dan tidak tersimpan.',
          style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Lanjutkan Rekam',
              style: AppTextStyles.bodyMd(c: AppColors.primary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text('Hentikan',
              style: AppTextStyles.bodyMd(c: AppColors.error)),
        ),
      ],
    );
  }
}