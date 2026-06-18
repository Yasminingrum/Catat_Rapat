import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/utils/snackbar_util.dart';

Future<void> showBagikanNotulaSheet(BuildContext context, {required Meeting meeting}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    isScrollControlled: true,
    builder: (ctx) => _BagikanNotulaSheet(meeting: meeting),
  );
}

class _BagikanNotulaSheet extends ConsumerWidget {
  const _BagikanNotulaSheet({required this.meeting});
  final Meeting meeting;

  String _buildShareText(Notula notula, List<Participant> participants) {
    String sub(String text) {
      var result = text;
      for (final p in participants) {
        if (p.name.isNotEmpty) result = result.replaceAll(p.label, p.name);
      }
      return result;
    }

    final buf = StringBuffer()
      ..writeln('NOTULA RAPAT: ${meeting.title}')
      ..writeln('${meeting.date} | ${meeting.time} | ${meeting.duration}')
      ..writeln('Peserta: ${participants.map((p) => p.displayName).join(', ')}')
      ..writeln();
    if (notula.ringkasan.isNotEmpty) {
      buf..writeln('Ringkasan:')..writeln(sub(notula.ringkasan))..writeln();
    }
    if (notula.keputusan.isNotEmpty) {
      buf.writeln('Keputusan:');
      for (final (i, k) in notula.keputusan.indexed) {
        buf.writeln('${i + 1}. ${k.text}');
      }
      buf.writeln();
    }
    if (notula.actionItems.isNotEmpty) {
      buf.writeln('Tindak Lanjut:');
      for (final (i, a) in notula.actionItems.indexed) {
        final status = a.status == ActionStatus.done ? '[Selesai]' : '[Pending]';
        buf.writeln('${i + 1}. $status ${a.text}'
            '${a.assignee.isNotEmpty ? ' → ${a.assignee}' : ''}'
            '${a.deadline.isNotEmpty ? ' (${a.deadline})' : ''}');
      }
    }
    return buf.toString().trimRight();
  }

  Future<void> _copyText(BuildContext context, AppStrings s, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) SnackbarUtil.showSuccess(context, s.bagikanNotulaCopied);
  }

  Future<void> _shareEmail(BuildContext context, AppStrings s, String text) async {
    final uri = Uri(scheme: 'mailto', queryParameters: {
      'subject': s.bagikanNotulaEmailSubject(meeting.title),
      'body': text,
    });
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) SnackbarUtil.showError(context, s.bagikanNotulaEmailError);
  }

  Future<void> _shareWhatsapp(BuildContext context, AppStrings s, String text) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) SnackbarUtil.showError(context, s.bagikanNotulaWhatsappError);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final notula = ref.watch(notulaProvider(meeting.id));
    final shareText = notula != null
        ? _buildShareText(notula, meeting.participants)
        : '';

    return Padding(
    padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
          decoration: const BoxDecoration(color: AppColors.divider, borderRadius: AppRadius.full))),
      Row(children: [
        Expanded(child: Text(s.bagikanNotulaTitle, style: AppTextStyles.displaySm(w: FontWeight.w700))),
        GestureDetector(onTap: () => Navigator.of(context).pop(),
          child: Container(width: 32, height: 32,
              decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
      ]),
      const SizedBox(height: 16),

      // Preview ringkasan
      Container(
        constraints: const BoxConstraints(maxHeight: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.borderMedium)),
        child: SingleChildScrollView(
          child: Text(shareText,
              style: AppTextStyles.bodySm(c: AppColors.textSecondary)),
        ),
      ),
      const SizedBox(height: 20),
      Center(child: Text(s.bagikanNotulaShareVia, style: AppTextStyles.bodySm(c: AppColors.textTertiary))),
      const SizedBox(height: 12),

      // Channels
      Row(children: [
        Expanded(child: _ChannelButton(icon: Icons.email_outlined, label: s.bagikanNotulaChannelEmail,
            color: AppColors.primary, bg: AppColors.primaryLight,
            onTap: () => _shareEmail(context, s, shareText))),
        const SizedBox(width: 12),
        Expanded(child: _ChannelButton(icon: Icons.chat_bubble_outline_rounded, label: s.bagikanNotulaChannelWhatsapp,
            color: AppColors.success, bg: AppColors.successLight,
            onTap: () => _shareWhatsapp(context, s, shareText))),
        const SizedBox(width: 12),
        Expanded(child: _ChannelButton(icon: Icons.copy_all_rounded, label: s.bagikanNotulaChannelCopy,
            color: AppColors.speaker2, bg: AppColors.speaker2Bg,
            onTap: () => _copyText(context, s, shareText))),
      ]),
    ]),
  );
  }
}

class _ChannelButton extends StatelessWidget {
  const _ChannelButton({required this.icon, required this.label, required this.color, required this.bg, required this.onTap});
  final IconData icon;
  final String label;
  final Color color, bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.lg),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.bodySm(c: color, w: FontWeight.w600)),
      ]),
    ),
  );
}
