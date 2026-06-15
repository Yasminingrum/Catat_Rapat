import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

/// Bottom sheet pemilihan satu opsi dari daftar, menampilkan tanda centang
/// pada opsi yang sedang aktif. Mengembalikan opsi terpilih lewat `pop`.
Future<T?> showOptionPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T) labelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(ctx).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(color: AppColors.divider, borderRadius: AppRadius.full))),
        Row(children: [
          Expanded(child: Text(title, style: AppTextStyles.displaySm(w: FontWeight.w700))),
          GestureDetector(onTap: () => Navigator.of(ctx).pop(),
            child: Container(width: 32, height: 32,
                decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
        ]),
        const SizedBox(height: 8),
        for (final opt in options)
          _OptionRow(
            label: labelOf(opt),
            selected: opt == selected,
            onTap: () => Navigator.of(ctx).pop(opt),
          ),
      ]),
    ),
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
      child: Row(children: [
        Expanded(child: Text(label,
            style: AppTextStyles.bodyMd(c: selected ? AppColors.primary : AppColors.textPrimary,
                w: selected ? FontWeight.w700 : FontWeight.w400))),
        if (selected)
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
        else
          Container(width: 20, height: 20,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.borderMedium))),
      ]),
    ),
  );
}
