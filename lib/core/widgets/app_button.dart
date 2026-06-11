import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, text, danger }

class AppButton extends StatefulWidget {
  const AppButton({super.key, required this.label, required this.onPressed,
    this.variant = AppButtonVariant.primary, this.isLoading = false,
    this.isFullWidth = true, this.icon, this.small = false});

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading, isFullWidth, small;
  final Widget? icon;

  @override State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _scale,
    builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
    child: GestureDetector(
      onTapDown: _disabled ? null : (_) => _ctrl.forward(),
      onTapUp: _disabled ? null : (_) { _ctrl.reverse(); widget.onPressed?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: _buildBody(),
    ),
  );

  Widget _buildBody() {
    final vPad = widget.small ? 10.0 : 16.0;
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        final bg = _disabled ? AppColors.divider
            : widget.variant == AppButtonVariant.danger ? AppColors.error : AppColors.primary;
        final textColor = _disabled ? AppColors.textDisabled : Colors.white;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isFullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 24),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.md,
              boxShadow: _disabled ? null : AppShadows.buttonPrimary),
          child: _inner(textColor),
        );
      case AppButtonVariant.secondary:
        return Container(
          width: widget.isFullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(vertical: vPad - 2, horizontal: 24),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.borderMedium)),
          child: _inner(AppColors.textPrimary));
      case AppButtonVariant.text:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: _inner(AppColors.primary));
    }
  }

  Widget _inner(Color textColor) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
    children: [
      if (widget.isLoading) ...[
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: textColor)),
        const SizedBox(width: 8),
      ] else if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
      Text(widget.label, style: AppTextStyles.displayXs(c: textColor, w: FontWeight.w600)),
    ],
  );
}
