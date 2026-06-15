import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/app_button.dart';

/// Assign Speaker Screen (PBI13).
///
/// Menampilkan suara (S1/S2/S3) hasil deteksi AI pada [transcriptProvider]
/// dan memungkinkan pengguna memberi nama peserta untuk tiap suara.
class AssignSpeakerScreen extends ConsumerStatefulWidget {
  const AssignSpeakerScreen({super.key, required this.title, this.duration, this.meetingId});

  final String title;
  final String? duration;
  final String? meetingId;

  @override
  ConsumerState<AssignSpeakerScreen> createState() => _AssignSpeakerScreenState();
}

class _AssignSpeakerScreenState extends ConsumerState<AssignSpeakerScreen> {
  final Map<String, String> _names = {};
  bool _saving = false;

  Future<void> _save(AppStrings s, List<_SpeakerEntry> speakers) async {
    final meetingId = widget.meetingId;
    if (meetingId == null) {
      context.pushReplacement('/home');
      return;
    }

    setState(() => _saving = true);
    final participants = speakers
        .map((s) => Participant(
              id: s.id,
              label: s.label,
              name: (_names[s.id] ?? '').trim(),
              color: s.color,
              colorBg: s.colorBg,
            ))
        .toList();

    try {
      await SupabaseService.instance.saveParticipants(meetingId, participants);
      await ref.read(meetingListProvider.notifier).refresh();
      if (!mounted) return;
      context.pushReplacement('/rapat/$meetingId');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarUtil.showError(context, s.assignSpeakerSaveError(e));
    }
  }

  List<_SpeakerEntry> _buildSpeakers(AppStrings s, List<TranscriptLine> transcript) {
    if (transcript.isEmpty) return [];

    final ids = transcript.map((l) => l.speakerId).toSet().toList()..sort();
    final talkSeconds = {for (final id in ids) id: 0};
    final previews = <String, String>{};

    for (var i = 0; i < transcript.length; i++) {
      final line = transcript[i];
      final start = _parseTimestamp(line.timestamp);
      final end = i + 1 < transcript.length
          ? _parseTimestamp(transcript[i + 1].timestamp)
          : start;
      final delta = end - start;
      if (delta > 0) {
        talkSeconds[line.speakerId] = (talkSeconds[line.speakerId] ?? 0) + delta;
      }
      previews.putIfAbsent(line.speakerId, () => line.text);
    }

    return ids.map((id) {
      final idx = int.tryParse(id.replaceAll('S', '')) ?? 1;
      return _SpeakerEntry(
        id: id,
        label: s.assignSpeakerVoiceLabel(idx),
        talkTime: _formatTalkTime(talkSeconds[id] ?? 0),
        color: AppColors.speakerColor(idx - 1),
        colorBg: AppColors.speakerBg(idx - 1),
        preview: previews[id] ?? '',
      );
    }).toList();
  }

  int _parseTimestamp(String hhmmss) {
    final parts = hhmmss.split(':');
    if (parts.length != 3) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = int.tryParse(parts[2]) ?? 0;
    return h * 3600 + m * 60 + s;
  }

  String _formatTalkTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final meetingId = widget.meetingId;
    final transcriptAsync = meetingId == null
        ? const AsyncValue<List<TranscriptLine>>.data(<TranscriptLine>[])
        : ref.watch(transcriptProvider(meetingId));
    final speakers = transcriptAsync.valueOrNull != null
        ? _buildSpeakers(s, transcriptAsync.value!)
        : <_SpeakerEntry>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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
                        Text(s.assignSpeakerTitle,
                            style: AppTextStyles.displayMd()),
                        Text(
                          transcriptAsync.isLoading
                              ? s.assignSpeakerLoadingDetection
                              : speakers.isEmpty
                                  ? s.assignSpeakerNoVoicesDetected
                                  : s.assignSpeakerDetectedCount(speakers.length),
                          style: AppTextStyles.bodySm(
                              c: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Info banner
            if (speakers.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.assignSpeakerInfoBanner,
                        style: AppTextStyles.bodySm(c: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

            // Speaker list
            Expanded(
              child: transcriptAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(s.assignSpeakerLoadError(e),
                        style: AppTextStyles.bodyMd(c: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                  ),
                ),
                data: (_) => speakers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            s.assignSpeakerNothingToAssign,
                            style: AppTextStyles.bodyMd(c: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        itemCount: speakers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) => _SpeakerCard(
                          s: s,
                          entry: speakers[i],
                          onNameChanged: (name) =>
                              setState(() => _names[speakers[i].id] = name),
                        ),
                      ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Column(
                children: [
                  AppButton(
                    label: speakers.isEmpty ? s.assignSpeakerContinueToNotula : s.assignSpeakerSaveMeeting,
                    isLoading: _saving,
                    onPressed: transcriptAsync.isLoading ? null : () => _save(s, speakers),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.assignSpeakerEmptyVoiceNote,
                    style: AppTextStyles.caption(c: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeakerEntry {
  _SpeakerEntry({
    required this.id,
    required this.label,
    required this.talkTime,
    required this.color,
    required this.colorBg,
    required this.preview,
  });

  final String id;
  final String label;
  final String talkTime;
  final Color color;
  final Color colorBg;
  final String preview;
}

class _SpeakerCard extends StatelessWidget {
  const _SpeakerCard({required this.s, required this.entry, required this.onNameChanged});

  final AppStrings s;
  final _SpeakerEntry entry;
  final void Function(String) onNameChanged;

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
          // Speaker header
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: entry.colorBg),
                child: Center(
                  child: Text(entry.id.replaceAll('S', ''),
                      style: AppTextStyles.bodySm(
                          c: entry.color, w: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.label,
                        style: AppTextStyles.bodyMd(
                            c: entry.color, w: FontWeight.w700)),
                    Text(s.assignSpeakerTalkTime(entry.talkTime),
                        style: AppTextStyles.caption(
                            c: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Preview quote
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: entry.colorBg,
              borderRadius: AppRadius.sm,
            ),
            child: Text(
              '"${entry.preview}"',
              style: AppTextStyles.bodySm(c: entry.color),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),

          // Name input
          Text(s.assignSpeakerParticipantNameLabel, style: AppTextStyles.label()),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: onNameChanged,
            style: AppTextStyles.bodyMd(),
            decoration: InputDecoration(
              hintText: s.assignSpeakerNameHint,
              hintStyle: AppTextStyles.bodyMd(c: AppColors.textDisabled),
              suffixIcon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.textTertiary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
