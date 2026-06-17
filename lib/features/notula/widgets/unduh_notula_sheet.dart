import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/services/docx_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/txt_service.dart';
import '../../../core/utils/snackbar_util.dart';

enum _DocFormat { pdf, docx, txt }

Future<void> showUnduhNotulaSheet(BuildContext context, {required Meeting meeting}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    isScrollControlled: true,
    builder: (ctx) => _UnduhNotulaSheet(meeting: meeting),
  );
}

class _UnduhNotulaSheet extends ConsumerStatefulWidget {
  const _UnduhNotulaSheet({required this.meeting});
  final Meeting meeting;

  @override
  ConsumerState<_UnduhNotulaSheet> createState() => _UnduhNotulaSheetState();
}

class _UnduhNotulaSheetState extends ConsumerState<_UnduhNotulaSheet> {
  _DocFormat? _loading;

  bool _isLocked(_DocFormat format, UserPlan plan) =>
      format != _DocFormat.pdf && plan == UserPlan.free;

  Future<void> _download(_DocFormat format) async {
    final notula = ref.read(notulaProvider(widget.meeting.id));
    if (notula == null) return;
    setState(() => _loading = format);
    try {
      switch (format) {
        case _DocFormat.pdf:
          await PdfService.instance.shareNotulaPdf(meeting: widget.meeting, notula: notula);
        case _DocFormat.docx:
          await DocxService.instance.shareNotulaDocx(meeting: widget.meeting, notula: notula);
        case _DocFormat.txt:
          await TxtService.instance.shareNotulaTxt(meeting: widget.meeting, notula: notula);
      }
    } catch (e) {
      if (mounted) SnackbarUtil.showError(context, ref.read(appStringsProvider).unduhNotulaError(e));
    } finally {
      if (mounted) setState(() => _loading = null);
    }
  }

  void _goToUpgrade() {
    Navigator.of(context).pop();
    context.push('/upgrade');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final plan = ref.watch(currentUserProvider)?.plan ?? UserPlan.free;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(color: AppColors.divider, borderRadius: AppRadius.full))),
        Row(children: [
          Expanded(child: Text(s.unduhNotulaTitle, style: AppTextStyles.displaySm(w: FontWeight.w700))),
          GestureDetector(onTap: () => Navigator.of(context).pop(),
            child: Container(width: 32, height: 32,
                decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
        ]),
        const SizedBox(height: 16),
        _FormatRow(
          format: _DocFormat.pdf,
          icon: Icons.picture_as_pdf_outlined,
          title: 'PDF',
          subtitle: s.unduhNotulaPdfSubtitle,
          color: AppColors.error, bg: AppColors.errorLight,
          loading: _loading == _DocFormat.pdf,
          locked: false,
          onTap: () => _download(_DocFormat.pdf),
        ),
        const SizedBox(height: 12),
        _FormatRow(
          format: _DocFormat.docx,
          icon: Icons.description_outlined,
          title: 'DOCX',
          subtitle: _isLocked(_DocFormat.docx, plan) ? s.unduhNotulaLockedSubtitle : s.unduhNotulaDocxSubtitle,
          color: AppColors.primary, bg: AppColors.primaryLight,
          loading: _loading == _DocFormat.docx,
          locked: _isLocked(_DocFormat.docx, plan),
          proBadge: s.unduhNotulaProBadge,
          onTap: _isLocked(_DocFormat.docx, plan) ? _goToUpgrade : () => _download(_DocFormat.docx),
        ),
        const SizedBox(height: 12),
        _FormatRow(
          format: _DocFormat.txt,
          icon: Icons.article_outlined,
          title: 'TXT',
          subtitle: _isLocked(_DocFormat.txt, plan) ? s.unduhNotulaLockedSubtitle : s.unduhNotulaTxtSubtitle,
          color: AppColors.textSecondary, bg: AppColors.background,
          loading: _loading == _DocFormat.txt,
          locked: _isLocked(_DocFormat.txt, plan),
          proBadge: s.unduhNotulaProBadge,
          onTap: _isLocked(_DocFormat.txt, plan) ? _goToUpgrade : () => _download(_DocFormat.txt),
        ),
      ]),
    );
  }
}

class _FormatRow extends StatelessWidget {
  const _FormatRow({
    required this.format, required this.icon, required this.title,
    required this.subtitle, required this.color, required this.bg,
    required this.loading, required this.locked, required this.onTap,
    this.proBadge,
  });
  final _DocFormat format;
  final IconData icon;
  final String title;
  final String? proBadge;
  final String subtitle;
  final Color color, bg;
  final bool loading;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = locked ? color.withValues(alpha: 0.4) : color;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Opacity(
        opacity: locked ? 0.75 : 1.0,
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.lg,
              border: format == _DocFormat.txt ? Border.all(color: AppColors.borderLight) : null),
          child: Row(children: [
            Icon(icon, color: effectiveColor, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(title, style: AppTextStyles.bodyMd(c: effectiveColor, w: FontWeight.w700)),
                if (locked && proBadge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient, borderRadius: AppRadius.full),
                    child: Text(proBadge!, style: AppTextStyles.caption(c: Colors.white, w: FontWeight.w700)),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.caption(c: AppColors.textSecondary)),
            ])),
            const SizedBox(width: 8),
            if (loading)
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: effectiveColor))
            else if (locked)
              Icon(Icons.lock_rounded, color: effectiveColor, size: 20)
            else
              Icon(Icons.download_rounded, color: color, size: 22),
          ]),
        ),
      ),
    );
  }
}
