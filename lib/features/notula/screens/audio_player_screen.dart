import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/app_bottom_nav.dart';

const _skipDuration = Duration(seconds: 15);
const _speedOptions = [1.0, 1.5, 2.0];

class AudioPlayerScreen extends ConsumerStatefulWidget {
  const AudioPlayerScreen({super.key, required this.meetingId});
  final String meetingId;
  @override ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  final _player = AudioPlayer();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  double _speed = 1.0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final meeting = await ref.read(meetingProvider(widget.meetingId).future);
      final path = meeting?.audioPath;
      if (path == null) {
        setState(() {
          _loading = false;
          _error = ref.read(appStringsProvider).audioPlayerNotAvailable;
        });
        return;
      }

      final url = await SupabaseService.instance.getAudioUrl(path);
      await _player.setUrl(url);

      _positionSub = _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _durationSub = _player.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });
      _stateSub = _player.playerStateStream.listen((s) {
        if (mounted) setState(() => _playing = s.playing);
      });

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = ref.read(appStringsProvider).audioPlayerLoadError(e);
        });
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _seekBy(Duration delta) {
    final target = _position + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _duration ? _duration : target);
    _player.seek(clamped);
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final meetingAsync = ref.watch(meetingProvider(widget.meetingId));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(16,12,16,12),
          child: Row(children: [
            GestureDetector(onTap: () => context.pop(),
              child: Container(width:32, height:32,
                decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderMedium)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size:14, color: AppColors.textPrimary))),
            const SizedBox(width:12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.audioPlayerHeaderLabel, style: AppTextStyles.label()),
              meetingAsync.when(data: (m) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m?.title ?? '', style: AppTextStyles.displayXs(),
                      maxLines:1, overflow: TextOverflow.ellipsis),
                  Text(m?.date ?? '', style: AppTextStyles.bodySm(c: AppColors.textSecondary)),
                ]),
                  loading: () => const SizedBox.shrink(), error: (_,__) => const SizedBox.shrink()),
            ])),
          ])),
        const Divider(height:1),

        Expanded(child: _error != null
          ? _ErrorView(s: s, message: _error!)
          : _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Spacer(),

                  // Kartu pemutar audio
                  Container(width: double.infinity, padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.xl,
                        border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
                    child: Column(children: [
                      // Ikon
                      Container(width: 96, height: 96,
                        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                        child: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 40)),
                      const SizedBox(height: 20),

                      // Title + date
                      meetingAsync.when(
                        data: (m) => Column(children: [
                          Text(m?.title ?? '', style: AppTextStyles.displayXs(w: FontWeight.w700), textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(m?.date ?? '', style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
                        ]),
                        loading: () => const SizedBox.shrink(), error: (_,__) => const SizedBox.shrink()),
                      const SizedBox(height: 24),

                      // Slider
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          activeTrackColor: AppColors.primary, inactiveTrackColor: AppColors.divider,
                          thumbColor: AppColors.primary, overlayColor: AppColors.primary.withValues(alpha: 0.1)),
                        child: Slider(
                            value: _position.inMilliseconds
                                .toDouble()
                                .clamp(0, _duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
                            max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                            onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal:4),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(_format(_position), style: AppTextStyles.bodySm(c: AppColors.textSecondary, w: FontWeight.w600)),
                          Text(_format(_duration), style: AppTextStyles.bodySm(c: AppColors.textSecondary, w: FontWeight.w600)),
                        ])),
                      const SizedBox(height: 24),

                      // Controls
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        // Skip -15s
                        GestureDetector(onTap: () => _seekBy(-_skipDuration),
                          child: Container(width:48, height:48, decoration: BoxDecoration(color: AppColors.background,
                              borderRadius: AppRadius.full, border: Border.all(color: AppColors.borderMedium)),
                            child: const Icon(Icons.replay_rounded, color: AppColors.textPrimary, size:22))),
                        const SizedBox(width: 16),
                        // Play/Pause
                        GestureDetector(onTap: () => _playing ? _player.pause() : _player.play(),
                          child: Container(width:64, height:64,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle,
                                boxShadow: AppShadows.buttonPrimary),
                            child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white, size:28))),
                        const SizedBox(width: 16),
                        // Skip +15s
                        GestureDetector(onTap: () => _seekBy(_skipDuration),
                          child: Container(width:48, height:48, decoration: BoxDecoration(color: AppColors.background,
                              borderRadius: AppRadius.full, border: Border.all(color: AppColors.borderMedium)),
                            child: const Icon(Icons.forward_rounded, color: AppColors.textPrimary, size:22))),
                      ]),
                      const SizedBox(height: 16),
                      Text(s.audioPlayerSkipHint, style: AppTextStyles.caption(c: AppColors.textTertiary)),
                    ])),
                  const SizedBox(height: 24),

                  // Speed
                  Row(mainAxisAlignment: MainAxisAlignment.center, children:
                    _speedOptions.map((speed) => GestureDetector(
                      onTap: () {
                        setState(() => _speed = speed);
                        _player.setSpeed(speed);
                      },
                      child: Container(margin: const EdgeInsets.symmetric(horizontal:6),
                        padding: const EdgeInsets.symmetric(horizontal:14, vertical:6),
                        decoration: BoxDecoration(
                          color: _speed == speed ? AppColors.primaryLight : Colors.transparent,
                          borderRadius: AppRadius.full),
                        child: Text('${speed}x', style: AppTextStyles.bodyMd(
                            c: _speed == speed ? AppColors.primary : AppColors.textTertiary,
                            w: _speed == speed ? FontWeight.w600 : FontWeight.w400))))).toList()),

                  const Spacer(),
                ]))),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.s, required this.message});
  final AppStrings s;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      const Spacer(),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.xl,
            border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.music_off_rounded, size: 32, color: AppColors.textTertiary)),
          const SizedBox(height: 20),
          Text(s.audioPlayerUnavailableTitle, style: AppTextStyles.displayXs(w: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.bodyMd(c: AppColors.textSecondary), textAlign: TextAlign.center),
        ])),
      const Spacer(),
    ]),
  );
}
