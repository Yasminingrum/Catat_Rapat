import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/snackbar_util.dart';

enum _BillingCycle { monthly, yearly }

class _PremiumFeature {
  const _PremiumFeature(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

List<_PremiumFeature> _premiumFeatures(AppStrings s) => [
  _PremiumFeature(Icons.mic_rounded, s.upgradeFeatureRecordingTitle, s.upgradeFeatureRecordingSubtitle),
  _PremiumFeature(Icons.description_rounded, s.upgradeFeatureNotulaTitle, s.upgradeFeatureNotulaSubtitle),
  _PremiumFeature(Icons.groups_rounded, s.upgradeFeatureParticipantsTitle, s.upgradeFeatureParticipantsSubtitle),
  _PremiumFeature(Icons.history_rounded, s.upgradeFeatureHistoryTitle, s.upgradeFeatureHistorySubtitle),
  _PremiumFeature(Icons.star_rounded, s.upgradeFeatureAccuracyTitle, s.upgradeFeatureAccuracySubtitle),
  _PremiumFeature(Icons.shield_rounded, s.upgradeFeatureEncryptionTitle, s.upgradeFeatureEncryptionSubtitle),
];

List<String> _freeTierItems(AppStrings s) => [
  s.upgradeFreeMinutes,
  s.upgradeFreeSpeakers,
  s.upgradeFreeHistory,
  s.upgradeFreeModel,
];

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});
  @override ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  _BillingCycle _cycle = _BillingCycle.yearly;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final priceLabel = _cycle == _BillingCycle.yearly ? 'Rp 29.000' : 'Rp 49.000';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16,12,16,28),
            decoration: const BoxDecoration(gradient: AppColors.quickActionGradient),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(onTap: () => context.pop(),
                child: Container(width:32, height:32,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size:14, color: Colors.white))),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.full),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.bolt_rounded, color: Colors.amber, size:14),
                    const SizedBox(width:6),
                    Text(s.upgradeBadge, style: AppTextStyles.bodySm(c: Colors.white, w: FontWeight.w700)),
                  ])),
              const SizedBox(height: 16),
              Text(s.upgradeHeadline, style: AppTextStyles.displayLg(c: Colors.white)),
              const SizedBox(height: 8),
              Text(s.upgradeSubtitle, style: AppTextStyles.bodyMd(c: Colors.white70)),
            ]),
          ),

          Padding(padding: const EdgeInsets.fromLTRB(24,24,24,0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Pilih paket
            Text(s.upgradeChoosePlan, style: AppTextStyles.label()),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _PlanOption(
                  label: s.upgradeMonthly, price: 'Rp 49.000', priceSub: s.upgradePerMonth,
                  selected: _cycle == _BillingCycle.monthly,
                  onTap: () => setState(() => _cycle = _BillingCycle.monthly))),
              const SizedBox(width: 12),
              Expanded(child: _PlanOption(
                  label: s.upgradeYearly, price: 'Rp 29.000', priceSub: s.upgradePerMonth,
                  badge: s.upgradeSaveBadge, footnote: s.upgradeBilledYearly,
                  selected: _cycle == _BillingCycle.yearly,
                  onTap: () => setState(() => _cycle = _BillingCycle.yearly))),
            ]),
            const SizedBox(height: 24),

            // Fitur premium
            Text(s.upgradePremiumFeaturesLabel, style: AppTextStyles.label()),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
                  border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
              child: Column(children: [
                for (final e in _premiumFeatures(s).asMap().entries)
                  _FeatureRow(feature: e.value, showDivider: e.key != _premiumFeatures(s).length - 1),
              ]),
            ),
            const SizedBox(height: 24),

            // Free tier
            Text(s.upgradeFreeTierLabel, style: AppTextStyles.label()),
            const SizedBox(height: 8),
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
                  border: Border.all(color: AppColors.borderLight)),
              child: Column(children: [
                for (final t in _freeTierItems(s)) _FreeTierRow(label: t),
              ]),
            ),
            const SizedBox(height: 24),

            // Testimoni
            Container(
              padding: AppSpacing.cardPadding,
              decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: AppColors.warning, size:18))),
                const SizedBox(height: 8),
                Text(s.upgradeTestimonial,
                    style: AppTextStyles.bodyMd(c: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(children: [
                  Container(width:32, height:32,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: Center(child: Text('RS', style: AppTextStyles.caption(c: Colors.white, w: FontWeight.w700)))),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Rizky S.', style: AppTextStyles.bodySm(w: FontWeight.w700)),
                    Text(s.upgradeTestimonialRole, style: AppTextStyles.caption()),
                  ]),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            // CTA
            GestureDetector(
              onTap: () => SnackbarUtil.showInfo(context, s.upgradePaymentUnavailable),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical:16),
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: AppRadius.md,
                    boxShadow: AppShadows.buttonPrimary),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size:18),
                  const SizedBox(width:8),
                  Text(s.upgradeCtaStart(priceLabel), style: AppTextStyles.bodyLg(c: Colors.white, w: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text(s.upgradeCtaFootnote, style: AppTextStyles.caption())),
          ])),
        ]),
      )),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.label, required this.price, required this.priceSub,
    this.badge, this.footnote, required this.selected, required this.onTap,
  });
  final String label, price, priceSub;
  final String? badge, footnote;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
          border: Border.all(color: selected ? AppColors.primary : AppColors.borderLight, width: selected ? 2 : 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMd(c: AppColors.textSecondary))),
          if (badge != null)
            Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:2),
                decoration: const BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.full),
                child: Text(badge!, style: AppTextStyles.caption(c: Colors.white, w: FontWeight.w700))),
          if (selected) ...[
            const SizedBox(width: 6),
            Container(width:20, height:20,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size:14)),
          ],
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(price, style: AppTextStyles.displaySm(w: FontWeight.w800)),
          Text(priceSub, style: AppTextStyles.caption()),
        ]),
        if (footnote != null) ...[
          const SizedBox(height: 4),
          Text(footnote!, style: AppTextStyles.caption(c: AppColors.textTertiary)),
        ],
      ]),
    ),
  );
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.showDivider});
  final _PremiumFeature feature;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Container(
    padding: AppSpacing.cardPadding,
    decoration: showDivider
        ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight)))
        : null,
    child: Row(children: [
      Container(width:36, height:36,
          decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.md),
          child: Icon(feature.icon, color: AppColors.primary, size:18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(feature.title, style: AppTextStyles.bodyMd(w: FontWeight.w700)),
        Text(feature.subtitle, style: AppTextStyles.caption(c: AppColors.textSecondary)),
      ])),
      const SizedBox(width: 8),
      Container(width:22, height:22,
          decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: AppColors.success, size:14)),
    ]),
  );
}

class _FreeTierRow extends StatelessWidget {
  const _FreeTierRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Container(width:16, height:16,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.textDisabled, width:1.5))),
      const SizedBox(width: 10),
      Text(label, style: AppTextStyles.bodyMd(c: AppColors.textTertiary)),
    ]),
  );
}
