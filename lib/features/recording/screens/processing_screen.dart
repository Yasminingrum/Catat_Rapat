import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/env_config.dart';
import '../../../core/widgets/app_button.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({
    super.key,
    required this.title,
    this.agenda,
    this.fileName,
    this.filePath,
    this.durationSeconds,
  });

  final String title;
  final String? agenda;
  final String? fileName;
  final String? filePath;
  final int? durationSeconds;

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0; // 0 - 100
  String? _error;
  late AnimationController _loaderController;

  static const List<_Stage> _stages = [
    _Stage('Mengunggah file', 20),
    _Stage('Menganalisis audio', 40),
    _Stage('Mendeteksi speaker', 70),
    _Stage('Membuat transkripsi', 95),
  ];

  @override
  void initState() {
    super.initState();

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _process();
  }

  @override
  void dispose() {
    _loaderController.dispose();
    super.dispose();
  }

  Future<void> _process() async {
    setState(() {
      _error = null;
      _progress = 0;
    });

    try {
      // ── Tahap 1: Upload — simpan rapat & unggah audio ──────
      final meeting = await SupabaseService.instance.createMeeting(
        title: widget.title,
        agenda: widget.agenda,
      );

      String? audioPath;
      if (widget.filePath != null) {
        audioPath = await SupabaseService.instance.uploadAudio(meeting.id, widget.filePath!);
      }
      if (!mounted) return;
      setState(() => _progress = 20);

      // ── Tahap 2-4: Analisis, deteksi speaker & transkripsi (Whisper) ──
      var transcript = <TranscriptLine>[];
      var durationSeconds = widget.durationSeconds;

      if (widget.filePath != null && EnvConfig.openAiApiKey.isNotEmpty) {
        final fileSize = await File(widget.filePath!).length();
        if (fileSize <= whisperMaxFileSizeBytes) {
          final result = await AiService.instance.transcribeAudio(
            audioPath: widget.filePath!,
            openAiKey: EnvConfig.openAiApiKey,
          );
          transcript = result.lines;
          durationSeconds ??= result.durationSeconds.round();
        }
      }
      if (!mounted) return;
      setState(() => _progress = 75);

      // ── Simpan transkrip, peserta hasil deteksi speaker & notula ──
      await SupabaseService.instance.saveTranscript(meeting.id, transcript);
      await SupabaseService.instance.saveParticipants(
          meeting.id, _participantsFromTranscript(transcript));

      Notula notula;
      if (transcript.isNotEmpty && EnvConfig.openAiApiKey.isNotEmpty) {
        notula = await AiService.instance.generateNotula(
          transcript: transcript,
          openAiKey: EnvConfig.openAiApiKey,
        );
      } else {
        notula = Notula(ringkasan: '', keputusan: [], actionItems: []);
      }
      await SupabaseService.instance.saveNotula(meeting.id, notula);

      final durationLabel = _formatDuration(durationSeconds ?? 0);
      await SupabaseService.instance.updateMeeting(meeting.id, {
        'duration': durationLabel,
        'status': 'final_',
        'has_audio': audioPath != null,
        'has_transcript': transcript.isNotEmpty,
        'has_notula': true,
        if (audioPath != null) 'audio_path': audioPath,
      });

      // Catat pemakaian token AI (1 token = 1 menit audio yang diproses).
      final minutesUsed = ((durationSeconds ?? 0) / 60).ceil();
      if (minutesUsed > 0) {
        await SupabaseService.instance.consumeTokens(minutesUsed);
        await ref.read(authProvider.notifier).refreshProfile();
      }

      if (!mounted) return;
      setState(() => _progress = 100);

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      context.pushReplacement('/assign-speaker', extra: {
        'meetingId': meeting.id,
        'title': widget.title,
        'duration': durationLabel,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  List<Participant> _participantsFromTranscript(List<TranscriptLine> transcript) {
    final ids = transcript.map((l) => l.speakerId).toSet().toList()..sort();
    return ids.map((id) {
      final idx = int.tryParse(id.replaceAll('S', '')) ?? 1;
      return Participant(
        id: id,
        label: 'Suara $idx',
        name: '',
        color: AppColors.speakerColor(idx - 1),
        colorBg: AppColors.speakerBg(idx - 1),
      );
    }).toList();
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}j ${m.toString().padLeft(2, '0')}m';
    return '${m}m ${s}s';
  }

  String get _statusTitle {
    if (_progress < 20) return 'Mengunggah file...';
    if (_progress < 40) return 'Menganalisis audio...';
    if (_progress < 70) return 'Mendeteksi speaker...';
    if (_progress < 100) return 'Membuat transkripsi...';
    return 'Selesai! ✓';
  }

  String get _statusSubtitle {
    if (_progress >= 100) return 'Selesai';
    if (_progress < 20) return 'Menyimpan rapat & mengunggah audio';
    if (_progress < 75) return 'AI sedang menganalisis audio, proses ini bisa memakan waktu';
    return 'Menyusun ringkasan dan action item';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ProcessingErrorView(
        message: _error!,
        onRetry: _process,
        onCancel: () => context.pop(),
      );
    }

    final isDone = _progress >= 100;
    // SVG circle math
    const radius = 88.0;
    const circumference = 2 * math.pi * radius;
    final dashOffset = circumference * (1 - _progress / 100);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Back disabled saat progress >= 100
                  GestureDetector(
                    onTap: isDone ? null : () => context.pop(),
                    child: AnimatedOpacity(
                      opacity: isDone ? 0.3 : 1,
                      duration: const Duration(milliseconds: 200),
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Memproses Rapat',
                            style: AppTextStyles.displayMd()),
                        const SizedBox(height: 2),
                        Text(widget.title,
                            style: AppTextStyles.bodyMd(
                                c: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  children: [
                    const Spacer(),

                    // ── Circular Progress ─────────────────────────
                    SizedBox(
                      width: 192,
                      height: 192,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background ring + progress ring
                          CustomPaint(
                            size: const Size(192, 192),
                            painter: _CircularProgressPainter(
                              progress: _progress,
                              circumference: circumference,
                              dashOffset: dashOffset,
                              isDone: isDone,
                            ),
                          ),

                          // Center content
                          if (isDone)
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.elasticOut,
                              builder: (_, v, __) => Transform.scale(
                                scale: v,
                                child: const Icon(Icons.check_circle_rounded,
                                    size: 56, color: AppColors.success),
                              ),
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RotationTransition(
                                  turns: _loaderController,
                                  child: const Icon(Icons.refresh_rounded,
                                      size: 28, color: AppColors.primary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_progress.round()}%',
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Status text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusTitle,
                        key: ValueKey(_statusTitle),
                        style: AppTextStyles.displaySm(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_statusSubtitle,
                        style: AppTextStyles.bodyMd(
                            c: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xxl),

                    // File info card
                    if (widget.fileName != null)
                      Container(
                        padding: AppSpacing.cardPadding,
                        margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.lg,
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: AppRadius.md,
                              ),
                              child: const Icon(Icons.upload_rounded,
                                  color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('FILE AUDIO',
                                      style: AppTextStyles.caption(
                                          c: AppColors.textTertiary)),
                                  Text(widget.fileName!,
                                      style: AppTextStyles.bodyMd(
                                          w: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 4 stages
                    ..._stages.map((stage) => _StageItem(
                          stage: stage,
                          progress: _progress,
                        )),

                    const Spacer(),

                    // Batalkan
                    if (!isDone)
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text('Batalkan',
                            style: AppTextStyles.bodyMd(
                                c: AppColors.textTertiary,
                                w: FontWeight.w500)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ProcessingErrorView extends StatelessWidget {
  const _ProcessingErrorView({
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 32, color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Pemrosesan Gagal',
                  style: AppTextStyles.displaySm(),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: AppTextStyles.bodyMd(c: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(label: 'Coba Lagi', onPressed: onRetry),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onCancel,
                child: Text('Batalkan',
                    style: AppTextStyles.bodyMd(c: AppColors.textTertiary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Circular Progress Painter ────────────────────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  const _CircularProgressPainter({
    required this.progress,
    required this.circumference,
    required this.dashOffset,
    required this.isDone,
  });

  final double progress;
  final double circumference;
  final double dashOffset;
  final bool isDone;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 88.0;

    // Background ring
    canvas.drawCircle(
      center, radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = AppColors.divider,
    );

    // Progress ring
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,     // start from top
      2 * math.pi * (progress / 100),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = isDone ? AppColors.success : AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.isDone != isDone;
}

// ─── Stage Item ───────────────────────────────────────────────────────────────

class _Stage {
  const _Stage(this.label, this.threshold);
  final String label;
  final double threshold;
}

class _StageItem extends StatelessWidget {
  const _StageItem({required this.stage, required this.progress});

  final _Stage stage;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final isDone = progress >= stage.threshold;
    final isActive = progress >= (stage.threshold - 20) &&
        progress < stage.threshold;

    Color indicatorColor;
    Widget indicatorChild;

    if (isDone) {
      indicatorColor = AppColors.success;
      indicatorChild = const Icon(Icons.check_rounded,
          size: 12, color: Colors.white);
    } else if (isActive) {
      indicatorColor = AppColors.primary;
      indicatorChild = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.2),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (_, v, __) => Transform.scale(
          scale: v,
          child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      indicatorColor = AppColors.divider;
      indicatorChild = const SizedBox.shrink();
    }

    Color textColor;
    FontWeight textWeight;
    if (isDone) {
      textColor = AppColors.success;
      textWeight = FontWeight.w600;
    } else if (isActive) {
      textColor = AppColors.primary;
      textWeight = FontWeight.w600;
    } else {
      textColor = AppColors.textTertiary;
      textWeight = FontWeight.w400;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: indicatorChild),
          ),
          const SizedBox(width: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: AppTextStyles.bodyMd(
                c: textColor, w: textWeight),
            child: Text(stage.label),
          ),
        ],
      ),
    );
  }
}
