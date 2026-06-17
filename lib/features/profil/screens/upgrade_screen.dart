import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/supabase_service.dart';
import 'payment_webview_screen.dart';

enum _BillingCycle { monthly, yearly }
enum _Plan { free, pro, platinum }

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

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});
  @override ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  _BillingCycle _cycle = _BillingCycle.yearly;
  _Plan _selected = _Plan.pro;
  bool _isLoading = false;

  String _ctaPrice() {
    final yearly = _cycle == _BillingCycle.yearly;
    return switch (_selected) {
      _Plan.pro      => yearly ? 'Rp 1.999.000/tahun' : 'Rp 199.000/bulan',
      _Plan.platinum => yearly ? 'Rp 5.499.000/tahun' : 'Rp 549.000/bulan',
      _Plan.free     => '',
    };
  }

  Future<void> _startPayment(BuildContext context, AppStrings s) async {
    setState(() => _isLoading = true);

    // Capture sebelum async gap agar tidak melanggar use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final router = GoRouter.of(context);

    try {
      final planName = _selected == _Plan.pro ? 'pro' : 'platinum';
      final cycle = _cycle == _BillingCycle.monthly ? 'monthly' : 'yearly';
      final token = await SupabaseService.instance.createPaymentToken(planName, cycle);

      if (!mounted) return;
      if (token == null) {
        _snack(messenger, s.upgradePaymentFetchError, AppColors.error);
        return;
      }

      final targetPlan = _selected == _Plan.pro ? UserPlan.pro : UserPlan.platinum;
      final result = await nav.push<PaymentResult>(
        MaterialPageRoute(builder: (_) => PaymentWebviewScreen(
          snapToken: token, plan: targetPlan,
        )),
      );

      if (!mounted) return;
      switch (result) {
        case PaymentResult.success:
          _snack(messenger, s.upgradePaymentSuccess, AppColors.success);
          router.pop();
        case PaymentResult.pending:
          _snack(messenger, s.upgradePaymentPending, AppColors.primary);
        case PaymentResult.error:
          _snack(messenger, s.upgradePaymentError, AppColors.error);
        case PaymentResult.cancelled:
        case null:
          break;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(ScaffoldMessengerState messenger, String message, Color color) {
    messenger.showSnackBar(SnackBar(
      content: Text(message,
        style: AppTextStyles.bodyMd(c: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final features = _premiumFeatures(s);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: const BoxDecoration(gradient: AppColors.quickActionGradient),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.full),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 6),
                  Text(s.upgradeBadge,
                    style: AppTextStyles.bodySm(c: Colors.white, w: FontWeight.w700)),
                ])),
              const SizedBox(height: 16),
              Text(s.upgradeHeadline, style: AppTextStyles.displayLg(c: Colors.white)),
              const SizedBox(height: 8),
              Text(s.upgradeSubtitle, style: AppTextStyles.bodyMd(c: Colors.white70)),
            ]),
          ),

          Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 0), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Billing toggle
              _BillingToggle(
                selected: _cycle,
                saveBadge: s.upgradeSaveBadge,
                labelMonthly: s.upgradeMonthly,
                labelYearly: s.upgradeYearly,
                onChanged: (c) => setState(() => _cycle = c),
              ),
              const SizedBox(height: 20),

              // Plan cards
              Text(s.upgradeChoosePlan, style: AppTextStyles.label()),
              const SizedBox(height: 8),

              // Free
              _PlanCard(
                name: s.upgradePlanFree,
                quota: s.upgradeFreeMinutes,
                price: s.upgradePriceFree,
                period: '',
                selected: _selected == _Plan.free,
                onTap: () => setState(() => _selected = _Plan.free),
              ),
              const SizedBox(height: 10),

              // Pro
              _PlanCard(
                name: s.upgradePlanPro,
                quota: s.upgradeProQuota,
                price: _cycle == _BillingCycle.yearly ? 'Rp 1.999.000' : 'Rp 199.000',
                period: _cycle == _BillingCycle.yearly ? s.upgradePerYear : s.upgradePerMonth,
                footnote: _cycle == _BillingCycle.yearly ? s.upgradeBilledYearlyPro : null,
                saveBadge: _cycle == _BillingCycle.yearly ? s.upgradeSaveBadge : null,
                isPrimary: true,
                selected: _selected == _Plan.pro,
                onTap: () => setState(() => _selected = _Plan.pro),
              ),
              const SizedBox(height: 10),

              // Platinum
              _PlanCard(
                name: s.upgradePlanPlatinum,
                quota: s.upgradePlatinumQuota,
                price: _cycle == _BillingCycle.yearly ? 'Rp 5.499.000' : 'Rp 549.000',
                period: _cycle == _BillingCycle.yearly ? s.upgradePerYear : s.upgradePerMonth,
                footnote: _cycle == _BillingCycle.yearly ? s.upgradeBilledYearlyPlatinum : null,
                saveBadge: _cycle == _BillingCycle.yearly ? s.upgradeSaveBadge : null,
                isPlatinum: true,
                selected: _selected == _Plan.platinum,
                onTap: () => setState(() => _selected = _Plan.platinum),
              ),
              const SizedBox(height: 24),

              // Fitur premium
              Text(s.upgradePremiumFeaturesLabel, style: AppTextStyles.label()),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: AppRadius.lg,
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppShadows.card),
                child: Column(children: [
                  for (final e in features.asMap().entries)
                    _FeatureRow(feature: e.value, showDivider: e.key != features.length - 1),
                ]),
              ),
              const SizedBox(height: 24),

              // Testimoni
              Container(
                padding: AppSpacing.cardPadding,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight, borderRadius: AppRadius.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: List.generate(5,
                    (_) => const Icon(Icons.star_rounded, color: AppColors.warning, size: 18))),
                  const SizedBox(height: 8),
                  Text(s.upgradeTestimonial,
                    style: AppTextStyles.bodyMd(c: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Container(width: 32, height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                      child: Center(child: Text('RS',
                        style: AppTextStyles.caption(c: Colors.white, w: FontWeight.w700)))),
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
              if (_selected != _Plan.free) ...[
                GestureDetector(
                  onTap: _isLoading ? null : () => _startPayment(context, s),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppRadius.md,
                      boxShadow: AppShadows.buttonPrimary),
                    child: _isLoading
                        ? const Center(child: SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5)))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(s.upgradeCtaStart(_ctaPrice()),
                              style: AppTextStyles.bodyLg(c: Colors.white, w: FontWeight.w700)),
                          ]),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Text(s.upgradeCtaFootnote, style: AppTextStyles.caption())),
              ],
            ],
          )),
        ]),
      )),
    );
  }
}

// ── Billing toggle ────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.selected, required this.saveBadge,
    required this.labelMonthly, required this.labelYearly,
    required this.onChanged,
  });
  final _BillingCycle selected;
  final String saveBadge, labelMonthly, labelYearly;
  final ValueChanged<_BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: const BoxDecoration(color: AppColors.divider, borderRadius: AppRadius.lg),
    child: Row(children: [
      Expanded(child: _ToggleBtn(
        label: labelMonthly,
        active: selected == _BillingCycle.monthly,
        onTap: () => onChanged(_BillingCycle.monthly),
      )),
      Expanded(child: _ToggleBtn(
        label: labelYearly,
        active: selected == _BillingCycle.yearly,
        badge: saveBadge,
        onTap: () => onChanged(_BillingCycle.yearly),
      )),
    ]),
  );
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label, required this.active, required this.onTap, this.badge,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.surface : Colors.transparent,
        borderRadius: AppRadius.md,
        boxShadow: active ? AppShadows.card : null,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: AppTextStyles.bodyMd(
          w: active ? FontWeight.w700 : FontWeight.w400,
          c: active ? AppColors.textPrimary : AppColors.textSecondary,
        )),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: const BoxDecoration(
              color: AppColors.success, borderRadius: AppRadius.full),
            child: Text(badge!,
              style: AppTextStyles.caption(c: Colors.white, w: FontWeight.w700)),
          ),
        ],
      ]),
    ),
  );
}

// ── Plan card ─────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name, required this.quota,
    required this.price, required this.period,
    this.footnote, this.saveBadge,
    this.isPrimary = false, this.isPlatinum = false,
    required this.selected, required this.onTap,
  });
  final String name, quota, price, period;
  final String? footnote, saveBadge;
  final bool isPrimary, isPlatinum, selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = isPlatinum
        ? Colors.amber.shade700
        : isPrimary
            ? AppColors.primary
            : AppColors.textSecondary;
    final borderColor = selected
        ? (isPlatinum ? Colors.amber.shade500 : AppColors.primary)
        : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: AppRadius.lg,
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          boxShadow: selected ? AppShadows.card : null,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (isPlatinum)
                Padding(padding: const EdgeInsets.only(right: 5),
                  child: Icon(Icons.diamond_rounded, color: accentColor, size: 15)),
              Text(name,
                style: AppTextStyles.bodyMd(w: FontWeight.w700, c: accentColor)),
            ]),
            const SizedBox(height: 3),
            Text(quota, style: AppTextStyles.caption(c: AppColors.textSecondary)),
            if (period.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic, children: [
                Text(price, style: AppTextStyles.displaySm(w: FontWeight.w800)),
                Text(period, style: AppTextStyles.caption()),
              ]),
              if (footnote != null) ...[
                const SizedBox(height: 2),
                Text(footnote!,
                  style: AppTextStyles.caption(c: AppColors.textTertiary)),
              ],
            ],
          ])),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (saveBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                  color: AppColors.success, borderRadius: AppRadius.full),
                child: Text(saveBadge!,
                  style: AppTextStyles.caption(c: Colors.white, w: FontWeight.w700))),
              const SizedBox(height: 6),
            ],
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: selected ? accentColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? accentColor : AppColors.borderLight, width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Feature row ───────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.showDivider});
  final _PremiumFeature feature;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Container(
    padding: AppSpacing.cardPadding,
    decoration: showDivider
        ? const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderLight)))
        : null,
    child: Row(children: [
      Container(width: 36, height: 36,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight, borderRadius: AppRadius.md),
        child: Icon(feature.icon, color: AppColors.primary, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(feature.title, style: AppTextStyles.bodyMd(w: FontWeight.w700)),
        Text(feature.subtitle,
          style: AppTextStyles.caption(c: AppColors.textSecondary)),
      ])),
      const SizedBox(width: 8),
      Container(width: 22, height: 22,
        decoration: const BoxDecoration(
          color: AppColors.successLight, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: AppColors.success, size: 14)),
    ]),
  );
}
