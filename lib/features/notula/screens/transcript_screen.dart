import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/meeting_model.dart' show TranscriptLine;
import '../../../core/providers/meeting_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';


class TranscriptScreen extends ConsumerStatefulWidget {
  const TranscriptScreen({super.key, required this.meetingId});
  final String meetingId;
  @override ConsumerState<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends ConsumerState<TranscriptScreen> {
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
          child: Row(children: [
            GestureDetector(onTap: () => context.pop(),
              child: Container(width:32, height:32,
                decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderMedium)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size:14, color: AppColors.textPrimary))),
            const SizedBox(width:12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.transcriptTitle, style: AppTextStyles.displayMd()),
              meetingAsync.when(
                  data: (m) => Text(m?.title ?? '', style: AppTextStyles.bodySm(c: AppColors.textSecondary)),
                  loading: () => const SizedBox.shrink(),
                  error: (_,__) => const SizedBox.shrink()),
            ])),
          ])),
        const Divider(height:1),

        // Transcript lines
        Expanded(child: transcriptAsync.when(
          data: (lines) {
            if (lines.isEmpty) {
              return Center(child: Text(s.transcriptEmpty,
                style: AppTextStyles.bodyMd(c: AppColors.textSecondary)));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24,16,24,16),
              itemCount: lines.length,
              separatorBuilder: (_,__) => const SizedBox(height:12),
              itemBuilder: (_, i) => _TranscriptTile(line: lines[i]));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e,_) => Center(child: Text(s.transcriptError(e))))),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _TranscriptTile extends StatelessWidget {
  const _TranscriptTile({required this.line});
  final TranscriptLine line;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(line.timestamp, style: AppTextStyles.caption(c: AppColors.textTertiary)
        .copyWith(fontFeatures: [const FontFeature.tabularFigures()])),
    const SizedBox(width: 12),
    Expanded(child: Text(line.text, style: AppTextStyles.bodyMd(c: const Color(0xFF334155)))),
  ]);
}
