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

class NotulaScreen extends ConsumerWidget {
  const NotulaScreen({super.key, required this.meetingId});
  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final meetingAsync = ref.watch(meetingProvider(meetingId));
    final notula = ref.watch(notulaProvider(meetingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        // Header
        Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(16,12,16,16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(onTap: () => context.pop(),
              child: Container(width:32, height:32,
                decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderMedium)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size:14, color: AppColors.textPrimary))),
            const SizedBox(width:12),
            Expanded(child: meetingAsync.when(
              data: (m) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m?.title ?? '', style: AppTextStyles.displayMd(w: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(m?.participants.map((p) => p.label).join(', ') ?? '',
                    style: AppTextStyles.bodySm(c: AppColors.textSecondary)),
              ]),
              loading: () => const SizedBox.shrink(), error: (_,__) => const SizedBox.shrink())),
          ])),
        const Divider(height:1),

        // Content
        Expanded(child: notula == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24,24,24,96),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Ringkasan
                _Card(title: s.notulaSummaryTitle,
                  child: Text(notula.ringkasan.isNotEmpty ? notula.ringkasan : s.notulaSummaryEmpty,
                      style: AppTextStyles.bodyMd(
                          c: notula.ringkasan.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary))),
                const SizedBox(height: 16),

                // Keputusan
                _Card(title: s.notulaDecisionsTitle,
                  child: notula.keputusan.isEmpty
                    ? Text(s.notulaDecisionsEmpty, style: AppTextStyles.bodyMd(c: AppColors.textTertiary))
                    : Column(children: notula.keputusan.asMap().entries.map((e) => Padding(
                        padding: EdgeInsets.only(bottom: e.key == notula.keputusan.length - 1 ? 0 : 10),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(width:24, height:24,
                              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                              child: Center(child: Text('${e.key+1}',
                                  style: AppTextStyles.caption(c: AppColors.primary, w: FontWeight.w700)))),
                          const SizedBox(width:10),
                          Expanded(child: Text(e.value.text, style: AppTextStyles.bodyMd())),
                        ]))).toList())),
                const SizedBox(height: 16),

                // Action Item
                _Card(
                  titleIcon: Container(width:28, height:28,
                      decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.sm),
                      child: const Icon(Icons.check_box_outlined, size:16, color: AppColors.primary)),
                  title: s.notulaActionItemTitle,
                  subtitle: s.notulaActionItemSubtitle,
                  child: notula.actionItems.isEmpty
                    ? Text(s.notulaActionItemEmpty, style: AppTextStyles.bodyMd(c: AppColors.textTertiary))
                    : Column(children: notula.actionItems.asMap().entries.map((e) => Padding(
                        padding: EdgeInsets.only(bottom: e.key == notula.actionItems.length - 1 ? 0 : 12),
                        child: GestureDetector(
                          onTap: () => ref.read(notulaProvider(meetingId).notifier).toggleActionStatus(e.value.id),
                          behavior: HitTestBehavior.opaque,
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width:20, height:20, margin: const EdgeInsets.only(top:1),
                              decoration: BoxDecoration(
                                  color: e.value.status == ActionStatus.done ? AppColors.primary : Colors.transparent,
                                  borderRadius: AppRadius.sm,
                                  border: Border.all(color: e.value.status == ActionStatus.done
                                      ? AppColors.primary : AppColors.borderMedium, width: 1.5)),
                              child: e.value.status == ActionStatus.done
                                  ? const Icon(Icons.check_rounded, size:14, color: Colors.white) : null),
                            const SizedBox(width:10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.value.text, style: AppTextStyles.bodyMd(w: FontWeight.w500)),
                              if (e.value.assignee.isNotEmpty || e.value.deadline.isNotEmpty) ...[
                                const SizedBox(height:2),
                                Row(children: [
                                  if (e.value.assignee.isNotEmpty)
                                    Text('→ ${e.value.assignee}',
                                        style: AppTextStyles.caption(c: AppColors.primary, w: FontWeight.w600)),
                                  if (e.value.assignee.isNotEmpty && e.value.deadline.isNotEmpty)
                                    const SizedBox(width: 10),
                                  if (e.value.deadline.isNotEmpty) ...[
                                    const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textTertiary),
                                    const SizedBox(width: 4),
                                    Text(e.value.deadline,
                                        style: AppTextStyles.caption(c: AppColors.textTertiary, w: FontWeight.w600)),
                                  ],
                                ]),
                              ],
                            ])),
                          ]),
                        ))).toList())),
                const SizedBox(height: 16),

                // Dengar Rekaman Audio / Lihat Transkripsi Lengkap
                meetingAsync.when(
                  data: (m) => Container(
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
                        border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
                    child: Column(children: [
                      if (m?.hasAudio == true || m?.audioPath != null) ...[
                        _QuickLinkRow(icon: Icons.volume_up_rounded,
                            iconBg: AppColors.successLight, iconColor: AppColors.success,
                            label: s.notulaListenAudio,
                            onTap: () => context.push('/rapat/$meetingId/audio')),
                        const Divider(height:1, indent:16, endIndent:16),
                      ],
                      _QuickLinkRow(icon: Icons.description_outlined,
                          iconBg: AppColors.primaryLight, iconColor: AppColors.primary,
                          label: s.notulaViewTranscript,
                          onTap: () => context.push('/rapat/$meetingId/transcript')),
                    ])),
                  loading: () => const SizedBox.shrink(), error: (_,__) => const SizedBox.shrink()),
                const SizedBox(height: 24),

                // Edit & Bagikan
                AppButton(
                  label: s.notulaEditAndShare,
                  onPressed: () => context.push('/rapat/$meetingId/edit-notula'),
                ),
              ]))),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, this.titleIcon, this.subtitle, required this.child});
  final String title;
  final String? subtitle;
  final Widget? titleIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: AppSpacing.cardPadding,
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (titleIcon != null) ...[titleIcon!, const SizedBox(width:8)],
        Text(title, style: AppTextStyles.displayXs(w: FontWeight.w700)),
      ]),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(subtitle!, style: AppTextStyles.caption(c: AppColors.textTertiary)),
      ],
      const SizedBox(height: 12),
      child,
    ]));
}

class _QuickLinkRow extends StatelessWidget {
  const _QuickLinkRow({required this.icon, required this.iconBg, required this.iconColor,
      required this.label, required this.onTap});
  final IconData icon;
  final Color iconBg, iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal:16, vertical:14),
      child: Row(children: [
        Container(width:36, height:36, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size:18, color: iconColor)),
        const SizedBox(width:12),
        Expanded(child: Text(label, style: AppTextStyles.bodyMd(w: FontWeight.w600))),
        const Icon(Icons.chevron_right_rounded, size:18, color: AppColors.textTertiary),
      ])));
}
