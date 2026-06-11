import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/app_button.dart';

class _PlanInfo {
  const _PlanInfo({
    required this.plan,
    required this.name,
    required this.price,
    required this.priceSub,
    required this.features,
    this.highlight = false,
  });

  final UserPlan plan;
  final String name;
  final String price;
  final String priceSub;
  final List<String> features;
  final bool highlight;
}

const _plans = [
  _PlanInfo(
    plan: UserPlan.free,
    name: 'Free',
    price: 'Rp 0',
    priceSub: '/bulan',
    features: [
      '5.000 token AI per bulan',
      'Maksimal 3 pembicara',
      'Riwayat rapat 30 hari',
      'Model AI standar',
      'Ekspor PDF',
    ],
  ),
  _PlanInfo(
    plan: UserPlan.pro,
    name: 'Pro',
    price: 'Rp 49.000',
    priceSub: '/bulan',
    highlight: true,
    features: [
      '20.000 token AI per bulan',
      'Maksimal 6 pembicara',
      'Riwayat rapat 90 hari',
      'Model AI prioritas (akurasi lebih tinggi)',
      'Ekspor PDF & Bagikan',
    ],
  ),
  _PlanInfo(
    plan: UserPlan.business,
    name: 'Business',
    price: 'Rp 199.000',
    priceSub: '/bulan',
    features: [
      'Token AI unlimited',
      'Hingga 10 pembicara',
      'Riwayat rapat selamanya',
      'Model AI terbaik untuk transkripsi',
      'Ekspor, Bagikan & kolaborasi tim',
    ],
  ),
];

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentPlan = user?.plan ?? UserPlan.free;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        // Header
        Container(color: const Color(0xFF4338CA),
          padding: const EdgeInsets.fromLTRB(16,12,16,24),
          child: Column(children: [
            Row(children: [
              GestureDetector(onTap: () => context.pop(),
                child: Container(width:32, height:32,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: AppRadius.full),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size:14, color: Colors.white))),
            ]),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.full),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size:16),
                  const SizedBox(width:6),
                  Text('CatatRapat Premium', style: AppTextStyles.bodySm(c: Colors.white, w: FontWeight.w700)),
                ])),
            const SizedBox(height: 12),
            Text('Pilih Paket yang\nSesuai Kebutuhanmu', style: AppTextStyles.displayLg(c: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Bandingkan fitur dan harga Free, Pro, dan Business', style: AppTextStyles.bodyMd(c: Colors.white70), textAlign: TextAlign.center),
          ])),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24,24,24,96),
          child: Column(children: [
            for (final info in _plans)
              _PlanCard(
                info: info,
                isCurrent: info.plan == currentPlan,
                onSelect: () => SnackbarUtil.showInfo(context,
                    'Pembayaran untuk paket ${info.name} belum tersedia di versi ini.'),
              ),
            const SizedBox(height: 8),
            Text('Hubungi tim kami untuk info lebih lanjut seputar upgrade paket.',
                style: AppTextStyles.bodySm(c: AppColors.textTertiary), textAlign: TextAlign.center),
          ]),
        )),
      ])),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.info, required this.isCurrent, required this.onSelect});
  final _PlanInfo info;
  final bool isCurrent;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: AppSpacing.cardPadding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.lg,
      border: Border.all(
          color: info.highlight ? AppColors.primary : AppColors.borderLight,
          width: info.highlight ? 2 : 1),
      boxShadow: AppShadows.card),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(info.name, style: AppTextStyles.displaySm(w: FontWeight.w700)),
        if (info.highlight) ...[
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:2),
              decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.full),
              child: Text('Populer', style: AppTextStyles.caption(c: AppColors.primary, w: FontWeight.w700))),
        ],
        const Spacer(),
        if (isCurrent)
          Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
              decoration: const BoxDecoration(color: AppColors.successLight, borderRadius: AppRadius.full),
              child: Text('Paket Aktif', style: AppTextStyles.caption(c: AppColors.success, w: FontWeight.w600))),
      ]),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text(info.price, style: AppTextStyles.displayLg(c: info.highlight ? AppColors.primary : AppColors.textPrimary)),
        const SizedBox(width: 4),
        Text(info.priceSub, style: AppTextStyles.bodySm(c: AppColors.textTertiary)),
      ]),
      const SizedBox(height: 16),
      ...info.features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(f, style: AppTextStyles.bodyMd(c: AppColors.textSecondary))),
        ]))),
      const SizedBox(height: 8),
      AppButton(
        label: isCurrent ? 'Paket Aktif' : 'Pilih Paket ${info.name}',
        onPressed: isCurrent ? null : onSelect,
        variant: isCurrent ? AppButtonVariant.secondary : AppButtonVariant.primary,
        small: true,
      ),
    ]));
}
