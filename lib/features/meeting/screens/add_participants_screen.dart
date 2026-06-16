import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/meeting_model.dart';
import '../../../core/providers/meeting_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/app_button.dart';

/// Halaman input peserta rapat — pengguna cukup mengetik nama,
/// tanpa perlu menghubungkan ke suara di transkrip.
class AddParticipantsScreen extends ConsumerStatefulWidget {
  const AddParticipantsScreen({
    super.key,
    required this.meetingId,
    required this.title,
    /// Jika true, setelah simpan layar di-pop (kembali ke layar sebelumnya).
    /// Jika false (pasca-processing), pushReplacement ke halaman detail rapat.
    this.popOnSave = false,
  });

  final String meetingId;
  final String title;
  final bool popOnSave;

  @override
  ConsumerState<AddParticipantsScreen> createState() => _AddParticipantsScreenState();
}

class _AddParticipantsScreenState extends ConsumerState<AddParticipantsScreen> {
  final List<TextEditingController> _controllers = [];
  bool _initialized = false;
  bool _saving = false;

  void _initControllers(List<Participant> existing) {
    if (_initialized) return;
    _initialized = true;
    if (existing.isNotEmpty) {
      for (final p in existing) {
        _controllers.add(TextEditingController(text: p.displayName));
      }
    } else {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addField() => setState(() => _controllers.add(TextEditingController()));

  void _removeField(int index) {
    if (_controllers.length <= 1) return;
    _controllers[index].dispose();
    setState(() => _controllers.removeAt(index));
  }

  Future<void> _save(AppStrings s) async {
    setState(() => _saving = true);
    try {
      final names = _controllers
          .map((c) => c.text.trim())
          .where((n) => n.isNotEmpty)
          .toList();

      final participants = names.asMap().entries.map((e) {
        final idx = e.key;
        return Participant(
          id: 'P${idx + 1}',
          label: 'Peserta ${idx + 1}',
          name: e.value,
          color: AppColors.speakerColor(idx),
          colorBg: AppColors.speakerBg(idx),
        );
      }).toList();

      await SupabaseService.instance.saveParticipants(widget.meetingId, participants);
      await ref.read(meetingListProvider.notifier).refresh();

      if (!mounted) return;
      if (widget.popOnSave) {
        context.pop();
      } else {
        context.pushReplacement('/rapat/${widget.meetingId}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarUtil.showError(context, s.addParticipantsSaveError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final meetingAsync = ref.watch(meetingProvider(widget.meetingId));
    final existing = meetingAsync.valueOrNull?.participants ?? [];
    _initControllers(existing);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderMedium),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 14, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.addParticipantsTitle, style: AppTextStyles.displayMd()),
                        Text(widget.title,
                            style: AppTextStyles.bodySm(c: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Info banner
            Container(
              margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.md,
                border: Border.all(color: const Color(0xFFE0E7FF)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.addParticipantsSubtitle,
                        style: AppTextStyles.bodySm(c: AppColors.primary)),
                  ),
                ],
              ),
            ),

            // Participant fields
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                itemCount: _controllers.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) => _ParticipantField(
                  controller: _controllers[i],
                  index: i,
                  canDelete: _controllers.length > 1,
                  onDelete: () => _removeField(i),
                ),
              ),
            ),

            // Add participant button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: GestureDetector(
                onTap: _addField,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.borderMedium),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(s.addParticipantsAdd,
                          style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  if (!widget.popOnSave) ...[
                    Expanded(
                      child: AppButton(
                        label: s.addParticipantsSkip,
                        variant: AppButtonVariant.secondary,
                        onPressed: _saving
                            ? null
                            : () => context.pushReplacement('/rapat/${widget.meetingId}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: AppButton(
                      label: s.addParticipantsSave,
                      isLoading: _saving,
                      onPressed: () => _save(s),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantField extends StatelessWidget {
  const _ParticipantField({
    required this.controller,
    required this.index,
    required this.canDelete,
    required this.onDelete,
  });

  final TextEditingController controller;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.speakerColor(index);
    final colorBg = AppColors.speakerBg(index);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          // Nomor urut peserta
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colorBg),
            child: Center(
              child: Text('${index + 1}',
                  style: AppTextStyles.bodySm(c: color, w: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: AppTextStyles.bodyMd(),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Peserta ${index + 1}',
                hintStyle: AppTextStyles.bodyMd(c: AppColors.textDisabled),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}
