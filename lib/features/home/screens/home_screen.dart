import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/meeting_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final meetingsAsync = ref.watch(visibleMeetingsProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        // Header
        Container(color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(24,16,24,16),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.homeGreeting(user?.name.split(' ').first ?? 'Pengguna'), style: AppTextStyles.displayLg()),
              const SizedBox(height: 2),
              Text(s.homeSubtitle, style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              GestureDetector(onTap: () => context.go('/profil'),
                child: Container(width: 40, height: 40,
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                  child: Center(child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                    style: AppTextStyles.bodyMd(c: Colors.white, w: FontWeight.w700))))),
              const SizedBox(height: 6),
              _TokenBar(percent: user?.tokenRemainingPercent ?? 0.5),
            ]),
          ])),

        // Content
        Expanded(child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(meetingListProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24,24,24,96),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Stats
              meetingsAsync.when(
                data: (m) => _StatsRow(s: s, total: m.length,
                    berjalan: m.where((x) => x.status == MeetingStatus.draft).length,
                    notulas: m.where((x) => x.hasNotula).length),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink()),
              const SizedBox(height: 24),

              // Quick action
              _QuickActionCard(s: s, onTap: () => context.push('/mulai-rapat')),
              const SizedBox(height: 24),

              // Rapat terbaru
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(s.homeRecentMeetings, style: AppTextStyles.displayXs()),
                GestureDetector(onTap: () => context.go('/riwayat'),
                    child: Text(s.homeSeeAll, style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w500))),
              ]),
              const SizedBox(height: 12),

              meetingsAsync.when(
                data: (meetings) => meetings.isEmpty
                    ? _EmptyState(s: s)
                    : Column(children: meetings.take(3).toList().asMap().entries.map((e) =>
                        Padding(padding: EdgeInsets.only(bottom: e.key < 2 ? 12 : 0),
                            child: MeetingCard(meeting: e.value,
                                onTap: () => context.push('/rapat/${e.value.id}')))).toList()),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('${s.commonLoadFailed}: $e',
                    style: AppTextStyles.bodyMd(c: AppColors.error)))),
            ]),
          ))),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _TokenBar extends StatelessWidget {
  const _TokenBar({required this.percent});
  final double percent;
  Color get _c => percent > 0.4 ? AppColors.success : percent > 0.15 ? AppColors.warning : AppColors.error;
  @override Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 64, height: 6, child: ClipRRect(borderRadius: AppRadius.full,
        child: LinearProgressIndicator(value: percent, backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(_c)))),
    const SizedBox(width: 6),
    Text('${(percent * 100).round()}%', style: AppTextStyles.caption(c: _c, w: FontWeight.w600)),
  ]);
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.s, required this.total, required this.berjalan, required this.notulas});
  final AppStrings s;
  final int total, berjalan, notulas;
  @override Widget build(BuildContext context) => Row(children: [
    Expanded(child: _Stat(s.homeStatTotal, '$total', Icons.mic_none_rounded, AppColors.primary)),
    const SizedBox(width: 12),
    Expanded(child: _Stat(s.homeStatOngoing, '$berjalan', Icons.radio_button_on_rounded, AppColors.error)),
    const SizedBox(width: 12),
    Expanded(child: _Stat(s.homeStatNotula, '$notulas', Icons.description_outlined, AppColors.success)),
  ]);
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label, value; final IconData icon; final Color color;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(height: 8),
      Text(value, style: AppTextStyles.displayMd(w: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption(c: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
    ]));
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.s, required this.onTap});
  final AppStrings s;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(gradient: AppColors.quickActionGradient,
          borderRadius: AppRadius.xl, boxShadow: AppShadows.buttonPrimary),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(s.homeQuickActionTitle, style: AppTextStyles.displaySm(c: Colors.white)),
          const SizedBox(height: 6),
          Text(s.homeQuickActionSubtitle, style: AppTextStyles.bodyMd(c: Colors.white70)),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.md,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.mic_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(s.homeQuickActionButton, style: AppTextStyles.bodySm(c: Colors.white, w: FontWeight.w600)),
            ])),
        ])),
        const Icon(Icons.mic_rounded, color: Colors.white30, size: 72),
      ])));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.s});
  final AppStrings s;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(children: [
      const Icon(Icons.calendar_today_outlined, size: 40, color: AppColors.divider),
      const SizedBox(height: 12),
      Text(s.homeEmptyTitle, style: AppTextStyles.bodyMd(c: AppColors.textSecondary, w: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(s.homeEmptySubtitle, style: AppTextStyles.bodySm(c: AppColors.textTertiary)),
    ]));
}
