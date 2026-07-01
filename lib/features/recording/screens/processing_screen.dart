import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/pending_recording_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/wav_writer.dart';
import '../../../core/widgets/app_button.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({
    super.key,
    required this.title,
    this.agenda,
    this.fileName,
    this.filePath,
    this.durationSeconds,
    this.existingMeetingId,
    this.existingAudioPath,
  });

  final String title;
  final String? agenda;
  final String? fileName;
  final String? filePath;
  final int? durationSeconds;
  /// Diisi saat memproses ulang rapat yang sudah ada di DB.
  final String? existingMeetingId;
  /// Path audio di Supabase Storage yang sudah terunggah sebelumnya.
  final String? existingAudioPath;

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0; // 0 - 100
  String? _error;
  late AnimationController _loaderController;

  // Disimpan agar retry tidak membuat rapat duplikat.
  String? _createdMeetingId;
  String? _uploadedAudioPath;

  List<_Stage> _stages(AppStrings s) => [
    _Stage(s.processingStageUpload, 20),
    _Stage(s.processingStageAnalyze, 40),
    _Stage(s.processingStageDetectSpeaker, 70),
    _Stage(s.processingStageTranscribe, 95),
  ];

  @override
  void initState() {
    super.initState();
    _createdMeetingId = widget.existingMeetingId;
    _uploadedAudioPath = widget.existingAudioPath;

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
      // ── Tahap 1: Buat rapat & unggah audio ────────────────
      // Dilewati pada retry agar tidak membuat rapat duplikat.
      final Meeting meeting;
      if (_createdMeetingId == null) {
        meeting = await SupabaseService.instance.createMeeting(
          title: widget.title,
          agenda: widget.agenda,
        );
        _createdMeetingId = meeting.id;
      } else {
        meeting = await SupabaseService.instance.getMeeting(_createdMeetingId!);
      }

      if (_uploadedAudioPath == null && widget.filePath != null) {
        // Downsample 24kHz → 16kHz untuk mengurangi ukuran file ~33%.
        // Jika masih >50MB (rekaman >26 menit), downsample lagi ke 8kHz
        // agar Edge Function Whisper tidak kehabisan memori.
        String uploadPath = widget.filePath!;
        if (uploadPath.endsWith('.wav')) {
          uploadPath = await WavWriter.downsample(uploadPath);           // 24k→16k
          final sz = await File(uploadPath).length();
          if (sz > 50 * 1024 * 1024) {
            final path8k = await WavWriter.downsample(uploadPath, dstRate: 8000); // 16k→8k
            if (path8k != uploadPath) {
              try { await File(uploadPath).delete(); } catch (_) {}
              uploadPath = path8k;
            }
          }
        }
        _uploadedAudioPath = await SupabaseService.instance
            .uploadAudio(meeting.id, uploadPath);
        if (_uploadedAudioPath != null) {
          await SupabaseService.instance.updateMeeting(meeting.id, {
            'has_audio': true,
            'audio_path': _uploadedAudioPath,
          });
        }
        // Hapus file sementara hasil downsample.
        if (uploadPath != widget.filePath!) {
          try { await File(uploadPath).delete(); } catch (_) {}
        }
      }
      final audioPath = _uploadedAudioPath;

      if (!mounted) return;
      setState(() => _progress = 20);

      // ── Tahap 2-4: Transkripsi via Edge Function `transcribe` ─
      var transcript = <TranscriptLine>[];
      var durationSeconds = widget.durationSeconds;

      if (audioPath != null) {
        final result = await SupabaseService.instance.invokeTranscribe(meeting.id);
        transcript = result.lines;
        durationSeconds = result.durationSeconds.round();
      }
      if (!mounted) return;
      setState(() => _progress = 75);

      // ── Simpan transkrip & notula ──────────────────────────
      await SupabaseService.instance.saveTranscript(meeting.id, transcript);

      final settings = ref.read(settingsProvider);

      final notula = transcript.isNotEmpty
          ? await SupabaseService.instance.invokeGenerateNotula(
              transcript,
              settings.notulaLanguage.name,
            )
          : Notula(ringkasan: '', keputusan: [], actionItems: []);

      await SupabaseService.instance.saveNotula(meeting.id, notula);
      if (settings.notifSummaryReady) {
        await NotificationService.instance.showSummaryReadyNotification(
          meetingId: meeting.id,
          meetingTitle: widget.title,
        );
      }
      if (settings.notifActionReminder && notula.actionItems.isNotEmpty) {
        await NotificationService.instance.scheduleActionItemReminders(
          meetingId: meeting.id,
          meetingTitle: widget.title,
          items: notula.actionItems,
        );
      }

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

      // Refresh providers agar layar yang sudah terbuka memuat data terbaru.
      ref.invalidate(notulaProvider(meeting.id));
      await ref.read(meetingListProvider.notifier).refresh();

      // Hapus dari antrian pending karena sudah berhasil diproses.
      if (widget.filePath != null) {
        await PendingRecordingService.instance.remove(widget.filePath!);
      }

      if (!mounted) return;
      setState(() => _progress = 100);

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      if (widget.existingMeetingId != null) {
        // Proses ulang: kembali ke NotulaScreen yang sudah ada di stack.
        context.pop();
      } else {
        context.pushReplacement('/rapat/${meeting.id}/peserta', extra: {
          'title': widget.title,
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e));
    }
  }

  /// Mengubah error mentah (terutama dari panggilan API AI) menjadi pesan
  /// yang lebih mudah dipahami pengguna.
  String _friendlyError(Object e) {
    final s = ref.read(appStringsProvider);
    if (e is DioException) {
      final status = e.response?.statusCode;
      switch (status) {
        case 401:
          return s.processingErrorInvalidApiKey;
        case 429:
          return s.processingErrorRateLimit;
        case null:
          return s.processingErrorNoConnection;
        default:
          return s.processingErrorGeneric(status);
      }
    }
    if (e is SocketException) {
      return s.processingErrorNoConnection;
    }
    final msg = e.toString().toLowerCase();
    if (msg.contains('payload too large') || msg.contains('maximum allowed size')) {
      return s.processingErrorFileTooLarge;
    }
    if (msg.contains('socket') || msg.contains('connection abort') || msg.contains('timeout')) {
      return s.processingErrorNoConnection;
    }
    return e.toString();
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}j ${m.toString().padLeft(2, '0')}m';
    return '${m}m ${s}s';
  }

  String _statusTitle(AppStrings s) {
    if (_progress < 20) return s.processingStatusUploading;
    if (_progress < 40) return s.processingStatusAnalyzing;
    if (_progress < 70) return s.processingStatusDetecting;
    if (_progress < 100) return s.processingStatusTranscribing;
    return s.processingStatusDone;
  }

  String _statusSubtitle(AppStrings s) {
    if (_progress >= 100) return s.processingSubtitleDone;
    if (_progress < 20) return s.processingSubtitleUploading;
    if (_progress < 75) return s.processingSubtitleAnalyzing;
    return s.processingSubtitleFinalizing;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    if (_error != null) {
      return _ProcessingErrorView(
        s: s,
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
                        Text(s.processingTitle,
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
                        _statusTitle(s),
                        key: ValueKey(_statusTitle(s)),
                        style: AppTextStyles.displaySm(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_statusSubtitle(s),
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
                                  Text(s.processingFileAudio,
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
                    ..._stages(s).map((stage) => _StageItem(
                          stage: stage,
                          progress: _progress,
                        )),

                    const Spacer(),

                    // Batalkan
                    if (!isDone)
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(s.processingCancel,
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
    required this.s,
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  final AppStrings s;
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
              Text(s.processingErrorTitle,
                  style: AppTextStyles.displaySm(),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: AppTextStyles.bodyMd(c: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(label: s.processingRetry, onPressed: onRetry),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onCancel,
                child: Text(s.processingCancel,
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
