import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_bottom_nav.dart';

class EditNotulaScreen extends ConsumerStatefulWidget {
  const EditNotulaScreen({super.key, required this.meetingId});
  final String meetingId;
  @override ConsumerState<EditNotulaScreen> createState() => _EditNotulaScreenState();
}

class _EditNotulaScreenState extends ConsumerState<EditNotulaScreen> {
  late TextEditingController _ringkasanCtrl;
  late List<TextEditingController> _keputusanCtrls;
  late List<Map<String, TextEditingController>> _actionCtrls;
  bool _initialized = false;

  void _init(Notula notula) {
    if (_initialized) return;
    _initialized = true;
    _ringkasanCtrl = TextEditingController(text: notula.ringkasan);
    _keputusanCtrls = notula.keputusan.map((k) => TextEditingController(text: k.text)).toList();
    _actionCtrls = notula.actionItems.map((a) => {
      'text': TextEditingController(text: a.text),
      'pic': TextEditingController(text: a.assignee),
      'deadline': TextEditingController(text: a.deadline),
    }).toList();
  }

  @override void dispose() {
    _ringkasanCtrl.dispose();
    for (var c in _keputusanCtrls) {
      c.dispose();
    }
    for (var m in _actionCtrls) { m['text']!.dispose(); m['pic']!.dispose(); m['deadline']!.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    final notula = ref.read(notulaProvider(widget.meetingId));
    if (notula == null) return;
    final updated = Notula(
      ringkasan: _ringkasanCtrl.text.trim(),
      keputusan: _keputusanCtrls.asMap().entries
          .where((e) => e.value.text.trim().isNotEmpty)
          .map((e) {
            final id = e.key < notula.keputusan.length
                ? notula.keputusan[e.key].id
                : DateTime.now().millisecondsSinceEpoch + e.key;
            return KeputusanItem(id: id, text: e.value.text.trim());
          }).toList(),
      actionItems: _actionCtrls.asMap().entries
          .where((e) => e.value['text']!.text.trim().isNotEmpty)
          .map((e) {
            final id = e.key < notula.actionItems.length
                ? notula.actionItems[e.key].id
                : DateTime.now().millisecondsSinceEpoch + e.key;
            final status = e.key < notula.actionItems.length
                ? notula.actionItems[e.key].status
                : ActionStatus.pending;
            return ActionItem(id: id, text: e.value['text']!.text.trim(),
                assignee: e.value['pic']!.text.trim(), deadline: e.value['deadline']!.text.trim(),
                status: status);
          }).toList(),
    );
    await ref.read(notulaProvider(widget.meetingId).notifier).save(updated);
    if (mounted) { SnackbarUtil.showSuccess(context, 'Notula berhasil disimpan'); context.pop(); }
  }

  @override
  Widget build(BuildContext context) {
    final notula = ref.watch(notulaProvider(widget.meetingId));
    if (notula == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _init(notula);

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
            Expanded(child: Text('Edit Notula', style: AppTextStyles.displayMd())),
            Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
                decoration: const BoxDecoration(color: AppColors.warningLight, borderRadius: AppRadius.full),
                child: Text('Draft', style: AppTextStyles.caption(c: AppColors.warning, w: FontWeight.w600))),
          ])),
        const Divider(height:1),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24,24,24,16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Ringkasan
            Text('RINGKASAN', style: AppTextStyles.label()),
            const SizedBox(height: 8),
            Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.borderMedium)),
              child: TextFormField(controller: _ringkasanCtrl, maxLines: 5,
                style: AppTextStyles.bodyMd(),
                decoration: const InputDecoration(border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14)))),
            const SizedBox(height: 24),

            // Keputusan
            Row(children: [
              Text('KEPUTUSAN', style: AppTextStyles.label()),
              const SizedBox(width:8),
              Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:2),
                  decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.full),
                  child: Text('${_keputusanCtrls.length}', style: AppTextStyles.caption(c: AppColors.primary, w: FontWeight.w700))),
            ]),
            const SizedBox(height: 8),
            ..._keputusanCtrls.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom:8),
              child: Row(children: [
                Container(width:24, height:24, decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.full),
                    child: Center(child: Text('${e.key+1}', style: AppTextStyles.caption(c: AppColors.primary, w: FontWeight.w700)))),
                const SizedBox(width:8),
                Expanded(child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.borderMedium)),
                  child: TextFormField(controller: e.value, maxLines: 2, style: AppTextStyles.bodyMd(),
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12))))),
                const SizedBox(width:8),
                GestureDetector(onTap: () => setState(() => _keputusanCtrls.removeAt(e.key)),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size:20)),
              ]))),
            GestureDetector(onTap: () => setState(() => _keputusanCtrls.add(TextEditingController())),
              child: Container(padding: const EdgeInsets.symmetric(vertical:10, horizontal:14),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.borderMedium, style: BorderStyle.solid)),
                child: Row(children: [
                  const Icon(Icons.add_rounded, size:16, color: AppColors.primary),
                  const SizedBox(width:6),
                  Text('+ Tambah keputusan baru...', style: AppTextStyles.bodyMd(c: AppColors.textTertiary)),
                ]))),
            const SizedBox(height: 24),

            // Action items
            Row(children: [
              Text('TINDAK LANJUT', style: AppTextStyles.label()),
              const SizedBox(width:8),
              Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:2),
                  decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.full),
                  child: Text('${_actionCtrls.length}', style: AppTextStyles.caption(c: AppColors.primary, w: FontWeight.w700))),
            ]),
            const SizedBox(height: 8),
            ..._actionCtrls.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom:12),
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
                  border: Border.all(color: AppColors.borderLight)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: TextFormField(controller: e.value['text'], style: AppTextStyles.bodyMd(),
                      maxLines: 2,
                      decoration: InputDecoration(hintText: 'Deskripsi tindak lanjut',
                          hintStyle: AppTextStyles.bodyMd(c: AppColors.textDisabled),
                          border: InputBorder.none, contentPadding: EdgeInsets.zero))),
                  GestureDetector(onTap: () => setState(() => _actionCtrls.removeAt(e.key)),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size:18)),
                ]),
                const Divider(height: 16),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('PIC', style: AppTextStyles.label()),
                    TextFormField(controller: e.value['pic'], style: AppTextStyles.bodyMd(),
                        decoration: InputDecoration(hintText: 'Nama...',
                            hintStyle: AppTextStyles.bodyMd(c: AppColors.textDisabled),
                            border: InputBorder.none, contentPadding: EdgeInsets.zero)),
                  ])),
                  const SizedBox(width:16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TENGGAT', style: AppTextStyles.label()),
                    TextFormField(controller: e.value['deadline'], style: AppTextStyles.bodyMd(),
                        decoration: InputDecoration(hintText: 'Tanggal...',
                            hintStyle: AppTextStyles.bodyMd(c: AppColors.textDisabled),
                            border: InputBorder.none, contentPadding: EdgeInsets.zero)),
                  ])),
                ]),
              ]))),
            GestureDetector(onTap: () => setState(() => _actionCtrls.add({
              'text': TextEditingController(), 'pic': TextEditingController(), 'deadline': TextEditingController()
            })),
              child: Container(padding: const EdgeInsets.symmetric(vertical:10, horizontal:14),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.borderMedium)),
                child: Row(children: [
                  const Icon(Icons.add_rounded, size:16, color: AppColors.primary),
                  const SizedBox(width:6),
                  Text('+ Tambah tindak lanjut baru...', style: AppTextStyles.bodyMd(c: AppColors.textTertiary)),
                ]))),
            const SizedBox(height: 32),
          ]))),

        // Bottom actions
        Container(padding: EdgeInsets.only(left:24, right:24, top:16,
            bottom: MediaQuery.of(context).padding.bottom + 16),
          decoration: const BoxDecoration(color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderLight))),
          child: Row(children: [
            Expanded(child: AppButton(label:'Batal', onPressed: () => context.pop(),
                variant: AppButtonVariant.secondary)),
            const SizedBox(width:12),
            Expanded(child: AppButton(label:'Simpan', onPressed: _save)),
          ])),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}
