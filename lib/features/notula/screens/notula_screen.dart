import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_button.dart';

class NotulaScreen extends ConsumerWidget {
  const NotulaScreen({super.key, required this.meetingId});
  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingAsync = ref.watch(meetingProvider(meetingId));
    final notula = ref.watch(notulaProvider(meetingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        // Header
        Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(16,12,16,12),
          child: Row(children: [
            GestureDetector(onTap: () => context.pop(),
              child: Container(width:32, height:32,
                decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderMedium)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size:14, color: AppColors.textPrimary))),
            const SizedBox(width:12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NOTULA RAPAT', style: AppTextStyles.label()),
              meetingAsync.when(
                data: (m) => Text(m?.title ?? '', style: AppTextStyles.displayXs(),
                    maxLines:1, overflow: TextOverflow.ellipsis),
                loading: () => const SizedBox.shrink(), error: (_,__) => const SizedBox.shrink()),
            ])),
            // Audio + Ekspor + Share
            Row(children: [
              if (meetingAsync.valueOrNull?.audioPath != null) ...[
                _IconBtn(icon: Icons.play_circle_outline_rounded,
                    onTap: () => context.push('/rapat/$meetingId/audio')),
                const SizedBox(width:8),
              ],
              _IconBtn(icon: Icons.download_rounded, onTap: () => _exportPdf(context, ref)),
              const SizedBox(width:8),
              _ShareBtn(onTap: () => _share(context, ref)),
            ]),
          ])),
        const Divider(height:1),

        // Content
        Expanded(child: notula == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24,24,24,96),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Meeting info card
                meetingAsync.when(
                  data: (m) => m != null ? _MeetingInfoCard(meeting: m) : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(), error: (_,__) => const SizedBox.shrink()),
                const SizedBox(height: 24),

                // Ringkasan
                _Section(title: 'I. PEMBAHASAN', content: notula.ringkasan),
                const SizedBox(height: 20),

                // Keputusan
                _KeputusanSection(items: notula.keputusan),
                const SizedBox(height: 20),

                // Action items
                _ActionItemsSection(items: notula.actionItems,
                    onToggle: (id) => ref.read(notulaProvider(meetingId).notifier).toggleActionStatus(id)),
                const SizedBox(height: 20),

                // Pengesahan
                _SignatureSection(),
                const SizedBox(height: 32),

                // Quick nav
                Row(children: [
                  Expanded(child: AppButton(
                    label: 'Lihat Transkripsi',
                    onPressed: () => context.push('/rapat/$meetingId/transcript'),
                    variant: AppButtonVariant.secondary,
                    small: true,
                    icon: const Icon(Icons.description_outlined, size:16, color: AppColors.textPrimary))),
                  const SizedBox(width:12),
                  Expanded(child: AppButton(
                    label: 'Edit Notula',
                    onPressed: () => context.push('/rapat/$meetingId/edit-notula'),
                    variant: AppButtonVariant.primary,
                    small: true,
                    icon: const Icon(Icons.edit_outlined, size:16, color: Colors.white))),
                ]),
              ]))),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Future<void> _exportPdf(BuildContext ctx, WidgetRef ref) async {
    final meeting = ref.read(meetingProvider(meetingId)).value;
    final notula  = ref.read(notulaProvider(meetingId));
    if (meeting == null || notula == null) return;
    try {
      await PdfService.instance.shareNotulaPdf(meeting: meeting, notula: notula);
    } catch (e) {
      if (ctx.mounted) SnackbarUtil.showError(ctx, 'Gagal ekspor PDF: $e');
    }
  }

  void _share(BuildContext ctx, WidgetRef ref) {
    final meeting = ref.read(meetingProvider(meetingId)).value;
    final notula  = ref.read(notulaProvider(meetingId));
    if (meeting == null || notula == null) return;

    final buffer = StringBuffer()
      ..writeln('*Notula Rapat: ${meeting.title}*')
      ..writeln('${meeting.date} • ${meeting.time} WIB • ${meeting.duration}')
      ..writeln();

    if (notula.ringkasan.isNotEmpty) {
      buffer
        ..writeln('*Pembahasan:*')
        ..writeln(notula.ringkasan)
        ..writeln();
    }
    if (notula.keputusan.isNotEmpty) {
      buffer.writeln('*Keputusan:*');
      for (final k in notula.keputusan) {
        buffer.writeln('- ${k.text}');
      }
      buffer.writeln();
    }
    if (notula.actionItems.isNotEmpty) {
      buffer.writeln('*Tindak Lanjut:*');
      for (final a in notula.actionItems) {
        final detail = [
          if (a.assignee.isNotEmpty) a.assignee,
          if (a.deadline.isNotEmpty) a.deadline,
        ].join(', ');
        buffer.writeln('- ${a.text}${detail.isNotEmpty ? ' ($detail)' : ''}');
      }
      buffer.writeln();
    }
    buffer.write('Dibuat dengan CatatRapat');

    Share.share(buffer.toString(), subject: 'Notula Rapat: ${meeting.title}');
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon; final VoidCallback onTap;
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width:36, height:36,
      decoration: BoxDecoration(color: AppColors.background, borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.borderMedium)),
      child: Icon(icon, size:18, color: AppColors.textPrimary)));
}

class _ShareBtn extends StatelessWidget {
  const _ShareBtn({required this.onTap});
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:8),
      decoration: const BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.md,
          boxShadow: AppShadows.buttonPrimary),
      child: Row(children: [
        const Icon(Icons.share_rounded, size:16, color: Colors.white),
        const SizedBox(width:6),
        Text('Bagikan', style: AppTextStyles.bodyMd(c: Colors.white, w: FontWeight.w600)),
      ])));
}

class _MeetingInfoCard extends StatelessWidget {
  const _MeetingInfoCard({required this.meeting});
  final Meeting meeting;
  @override Widget build(BuildContext context) => Container(
    padding: AppSpacing.cardPadding,
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(meeting.title, style: AppTextStyles.displayXs(w: FontWeight.w700))),
        Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
            decoration: const BoxDecoration(color: AppColors.successLight, borderRadius: AppRadius.full),
            child: Text('Siap Ekspor', style: AppTextStyles.caption(c: AppColors.success, w: FontWeight.w600))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _InfoPair('TANGGAL', meeting.date), const SizedBox(width:24),
        _InfoPair('WAKTU', '${meeting.time} WIB'), const SizedBox(width:24),
        _InfoPair('DURASI', meeting.duration),
      ]),
      const SizedBox(height: 8),
      _InfoPair('PESERTA', meeting.participants.map((p) => p.displayName).join(', ')),
    ]));
}

class _InfoPair extends StatelessWidget {
  const _InfoPair(this.label, this.value);
  final String label, value;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: AppTextStyles.label()),
    Text(value, style: AppTextStyles.bodyMd()),
  ]);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});
  final String title, content;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: AppTextStyles.displayXs(c: AppColors.textTertiary, w: FontWeight.w700)),
    const SizedBox(height: 8),
    Text(content.isNotEmpty ? content : 'Belum ada ringkasan.',
        style: AppTextStyles.bodyMd(c: content.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary)),
  ]);
}

class _KeputusanSection extends StatelessWidget {
  const _KeputusanSection({required this.items});
  final List<KeputusanItem> items;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text('II. KEPUTUSAN RAPAT', style: AppTextStyles.displayXs(c: AppColors.textTertiary, w: FontWeight.w700)),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:2),
          decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.full),
          child: Text('${items.length}', style: AppTextStyles.caption(c: AppColors.primary, w: FontWeight.w700))),
    ]),
    const SizedBox(height: 12),
    if (items.isEmpty)
      Text('Belum ada keputusan tercatat.', style: AppTextStyles.bodyMd(c: AppColors.textTertiary))
    else
      ...items.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom:10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width:24, height:24, decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.full),
              child: Center(child: Text('${e.key+1}', style: AppTextStyles.caption(c: AppColors.primary, w: FontWeight.w700)))),
          const SizedBox(width:10),
          Expanded(child: Text(e.value.text, style: AppTextStyles.bodyMd())),
        ]))),
  ]);
}

class _ActionItemsSection extends StatelessWidget {
  const _ActionItemsSection({required this.items, required this.onToggle});
  final List<ActionItem> items;
  final void Function(int id) onToggle;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text('III. TINDAK LANJUT', style: AppTextStyles.displayXs(c: AppColors.textTertiary, w: FontWeight.w700)),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:2),
          decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.full),
          child: Text('${items.length}', style: AppTextStyles.caption(c: AppColors.primary, w: FontWeight.w700))),
    ]),
    const SizedBox(height: 12),
    if (items.isEmpty)
      Text('Belum ada tindak lanjut tercatat.', style: AppTextStyles.bodyMd(c: AppColors.textTertiary))
    else
    ...items.map((a) => Container(
      margin: const EdgeInsets.only(bottom:10),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.borderLight)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(onTap: () => onToggle(a.id),
            child: Icon(a.status == ActionStatus.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size:20, color: a.status == ActionStatus.done ? AppColors.success : AppColors.divider)),
        const SizedBox(width:10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.text, style: AppTextStyles.bodyMd(
              w: a.status == ActionStatus.done ? FontWeight.w400 : FontWeight.w500)),
          const SizedBox(height:6),
          Row(children: [
            const Icon(Icons.person_outline_rounded, size:12, color: AppColors.primary),
            const SizedBox(width:4),
            Text(a.assignee.isNotEmpty ? a.assignee : '—',
                style: AppTextStyles.caption(c: AppColors.primary, w: FontWeight.w600)),
            const SizedBox(width:16),
            const Icon(Icons.calendar_today_outlined, size:12, color: AppColors.textTertiary),
            const SizedBox(width:4),
            Text(a.deadline.isNotEmpty ? a.deadline : '—',
                style: AppTextStyles.caption(c: AppColors.textTertiary)),
          ]),
        ])),
      ]))),
  ]);
}

class _SignatureSection extends StatelessWidget {
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('PENGESAHAN', style: AppTextStyles.displayXs(c: AppColors.textTertiary, w: FontWeight.w700)),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: Column(children: [
        Container(height: 60),
        const Divider(), Text('Notulis', style: AppTextStyles.bodyMd()),
      ])),
      const SizedBox(width: 24),
      Expanded(child: Column(children: [
        Container(height: 60),
        const Divider(), Text('Pimpinan Rapat', style: AppTextStyles.bodyMd()),
      ])),
    ]),
  ]);
}
