import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_button.dart';

class TranscriptScreen extends ConsumerStatefulWidget {
  const TranscriptScreen({super.key, required this.meetingId});
  final String meetingId;
  @override ConsumerState<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends ConsumerState<TranscriptScreen> {
  String? _activeSpeaker;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final meetingAsync = ref.watch(meetingProvider(widget.meetingId));
    final transcriptAsync = ref.watch(transcriptProvider(widget.meetingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        // Header
        Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(16,12,16,12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: () => context.pop(),
                child: Container(width:32, height:32,
                  decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderMedium)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size:14, color: AppColors.textPrimary))),
              const SizedBox(width:12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.transcriptTitle, style: AppTextStyles.displayMd()),
                meetingAsync.when(data: (m) => Text(m?.title ?? '', style: AppTextStyles.bodySm(c: AppColors.textSecondary)),
                    loading: () => const SizedBox.shrink(), error: (_,__) => const SizedBox.shrink()),
              ])),
            ]),
            const SizedBox(height: 12),
            // Speaker filter pills
            meetingAsync.when(
              data: (m) => m != null ? SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(children: [null, ...m.participants].map((p) {
                  final isActive = p == null ? _activeSpeaker == null : _activeSpeaker == p.id;
                  return GestureDetector(
                    onTap: () => setState(() => _activeSpeaker = p?.id),
                    child: Container(margin: const EdgeInsets.only(right:8),
                      padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
                      decoration: BoxDecoration(
                        color: isActive ? (p != null ? p.color : AppColors.primary) : AppColors.background,
                        borderRadius: AppRadius.full,
                        border: Border.all(color: isActive ? Colors.transparent : AppColors.borderMedium)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (p != null) ...[Container(width:8, height:8,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                                color: isActive ? Colors.white : p.color)), const SizedBox(width:6)],
                        Text(p?.displayName ?? s.transcriptAllSpeakers, style: AppTextStyles.bodySm(
                            c: isActive ? Colors.white : AppColors.textSecondary, w: FontWeight.w500)),
                      ])));
                }).toList())) : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(), error: (_,__) => const SizedBox.shrink()),
          ])),
        const Divider(height:1),

        // Transcript lines
        Expanded(child: transcriptAsync.when(
          data: (lines) {
            final filtered = _activeSpeaker == null ? lines
                : lines.where((l) => l.speakerId == _activeSpeaker).toList();
            if (filtered.isEmpty) {
              return Center(child: Text(s.transcriptEmpty,
                style: AppTextStyles.bodyMd(c: AppColors.textSecondary)));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24,16,24,16),
              itemCount: filtered.length,
              separatorBuilder: (_,__) => const SizedBox(height:12),
              itemBuilder: (_, i) => _TranscriptTile(line: filtered[i]));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e,_) => Center(child: Text(s.transcriptError(e))))),

        // Edit Peserta Rapat
        Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
          decoration: const BoxDecoration(color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderLight))),
          child: AppButton(
            label: s.transcriptEditParticipants,
            icon: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
            onPressed: meetingAsync.valueOrNull == null ? null : () => context.push('/assign-speaker', extra: {
              'meetingId': widget.meetingId,
              'title': meetingAsync.valueOrNull?.title ?? '',
              'duration': meetingAsync.valueOrNull?.duration,
            }),
          ),
        ),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _TranscriptTile extends StatelessWidget {
  const _TranscriptTile({required this.line});
  final TranscriptLine line;

  static Color _speakerColor(String id) {
    final i = int.tryParse(id.replaceAll('S','')) ?? 1;
    return AppColors.speakerColor(i-1);
  }
  static Color _speakerBg(String id) {
    final i = int.tryParse(id.replaceAll('S','')) ?? 1;
    return AppColors.speakerBg(i-1);
  }

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Column(children: [
      Text(line.timestamp, style: AppTextStyles.caption(c: AppColors.textTertiary)
          .copyWith(fontFeatures: [const FontFeature.tabularFigures()])),
    ]),
    const SizedBox(width: 10),
    Container(width:22, height:22, decoration: BoxDecoration(shape: BoxShape.circle,
        color: _speakerBg(line.speakerId)),
        child: Center(child: Text(line.speakerId.replaceAll('S',''),
            style: AppTextStyles.caption(c: _speakerColor(line.speakerId), w: FontWeight.w700)))),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(line.speaker, style: AppTextStyles.caption(c: _speakerColor(line.speakerId), w: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(line.text, style: AppTextStyles.bodyMd(c: const Color(0xFF334155))),
    ])),
  ]);
}
