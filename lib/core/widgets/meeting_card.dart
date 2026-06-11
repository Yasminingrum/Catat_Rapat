import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../models/meeting_model.dart';

class MeetingCard extends StatelessWidget {
  const MeetingCard({super.key, required this.meeting, required this.onTap});
  final Meeting meeting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40,
            decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.md),
            child: const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(meeting.title, style: AppTextStyles.displayXs(w: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            _StatusBadge(status: meeting.status),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(meeting.date, style: AppTextStyles.caption(c: AppColors.textSecondary)),
            const SizedBox(width: 12),
            const Icon(Icons.timer_outlined, size: 11, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(meeting.duration, style: AppTextStyles.caption(c: AppColors.textTertiary)),
          ]),
          const SizedBox(height: 8),
          _ParticipantAvatars(participants: meeting.participants),
        ])),
        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
      ]),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final MeetingStatus status;

  @override
  Widget build(BuildContext context) {
    final isDraft = status == MeetingStatus.draft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: isDraft ? AppColors.warningLight : AppColors.successLight,
          borderRadius: AppRadius.full),
      child: Text(isDraft ? 'Draft' : 'Selesai',
          style: AppTextStyles.caption(
              c: isDraft ? AppColors.warning : AppColors.success, w: FontWeight.w600)),
    );
  }
}

class _ParticipantAvatars extends StatelessWidget {
  const _ParticipantAvatars({required this.participants});
  final List<Participant> participants;

  @override
  Widget build(BuildContext context) {
    const size = 24.0;
    final count = participants.length.clamp(0, 3);
    return Row(children: [
      SizedBox(height: size, width: count * (size - 6) + 6,
          child: Stack(children: List.generate(count, (i) => Positioned(
            left: i * (size - 6).toDouble(),
            child: Container(width: size, height: size,
                decoration: BoxDecoration(color: participants[i].colorBg, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5)),
                child: Center(child: Text(
                  participants[i].displayName.isNotEmpty ? participants[i].displayName[0].toUpperCase() : '?',
                  style: AppTextStyles.caption(c: participants[i].color, w: FontWeight.w700),
                ))),
          )))),
      const SizedBox(width: 6),
      Text('${participants.length} peserta', style: AppTextStyles.caption(c: AppColors.textTertiary)),
    ]);
  }
}
