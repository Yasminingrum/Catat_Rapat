import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/docx_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/txt_service.dart';
import '../../../core/utils/snackbar_util.dart';

enum _DocFormat { pdf, docx, txt }

Future<void> showUnduhNotulaSheet(BuildContext context, {required Meeting meeting, required Notula notula}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    isScrollControlled: true,
    builder: (ctx) => _UnduhNotulaSheet(meeting: meeting, notula: notula),
  );
}

class _UnduhNotulaSheet extends ConsumerStatefulWidget {
  const _UnduhNotulaSheet({required this.meeting, required this.notula});
  final Meeting meeting;
  final Notula notula;

  @override
  ConsumerState<_UnduhNotulaSheet> createState() => _UnduhNotulaSheetState();
}

class _UnduhNotulaSheetState extends ConsumerState<_UnduhNotulaSheet> {
  _DocFormat? _loading;

  Future<void> _download(_DocFormat format) async {
    setState(() => _loading = format);
    try {
      switch (format) {
        case _DocFormat.pdf:
          await PdfService.instance.shareNotulaPdf(meeting: widget.meeting, notula: widget.notula);
        case _DocFormat.docx:
          await DocxService.instance.shareNotulaDocx(meeting: widget.meeting, notula: widget.notula);
        case _DocFormat.txt:
          await TxtService.instance.shareNotulaTxt(meeting: widget.meeting, notula: widget.notula);
      }
    } catch (e) {
      if (mounted) SnackbarUtil.showError(context, ref.read(appStringsProvider).unduhNotulaError(e));
    } finally {
      if (mounted) setState(() => _loading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final defaultFormat = ref.watch(settingsProvider).exportFormat;
    String? badgeFor(ExportFormat matches, String? fallback) =>
        defaultFormat == matches ? s.unduhNotulaDefaultBadge : fallback;

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
          title: 'PDF', badge: badgeFor(ExportFormat.pdf, s.unduhNotulaRecommendedBadge),
          subtitle: s.unduhNotulaPdfSubtitle,
          color: AppColors.error, bg: AppColors.errorLight,
          loading: _loading == _DocFormat.pdf,
          onTap: () => _download(_DocFormat.pdf),
        ),
        const SizedBox(height: 12),
        _FormatRow(
          format: _DocFormat.docx,
          icon: Icons.description_outlined,
          title: 'DOCX', badge: badgeFor(ExportFormat.docx, null),
          subtitle: s.unduhNotulaDocxSubtitle,
          color: AppColors.primary, bg: AppColors.primaryLight,
          loading: _loading == _DocFormat.docx,
          onTap: () => _download(_DocFormat.docx),
        ),
        const SizedBox(height: 12),
        _FormatRow(
          format: _DocFormat.txt,
          icon: Icons.article_outlined,
          title: 'TXT', badge: badgeFor(ExportFormat.txt, null),
          subtitle: s.unduhNotulaTxtSubtitle,
          color: AppColors.textSecondary, bg: AppColors.background,
          loading: _loading == _DocFormat.txt,
          onTap: () => _download(_DocFormat.txt),
        ),
      ]),
    );
  }
}

class _FormatRow extends StatelessWidget {
  const _FormatRow({
    required this.format, required this.icon, required this.title, this.badge,
    required this.subtitle, required this.color, required this.bg,
    required this.loading, required this.onTap,
  });
  final _DocFormat format;
  final IconData icon;
  final String title;
  final String? badge;
  final String subtitle;
  final Color color, bg;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.lg,
          border: format == _DocFormat.txt ? Border.all(color: AppColors.borderLight) : null),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: AppTextStyles.bodyMd(c: color, w: FontWeight.w700)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: const BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.full),
                  child: Text(badge!, style: AppTextStyles.caption(c: color, w: FontWeight.w600))),
            ],
          ]),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.caption(c: AppColors.textSecondary)),
        ])),
        const SizedBox(width: 8),
        if (loading)
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color))
        else
          Icon(Icons.download_rounded, color: color, size: 22),
      ]),
    ),
  );
}
