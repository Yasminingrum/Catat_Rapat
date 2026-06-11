import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_bottom_nav.dart';

enum RecordMode { live, upload }

const _maxAudioSizeBytes = 500 * 1024 * 1024;
const _allowedAudioExtensions = ['mp3', 'm4a', 'wav', 'ogg'];

class MulaiRapatScreen extends ConsumerStatefulWidget {
  const MulaiRapatScreen({super.key});

  @override
  ConsumerState<MulaiRapatScreen> createState() => _MulaiRapatScreenState();
}

class _MulaiRapatScreenState extends ConsumerState<MulaiRapatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _agendaController = TextEditingController();

  RecordMode _mode = RecordMode.live;
  String? _selectedFileName;
  String? _selectedFilePath;

  bool get _canStart {
    if (_titleController.text.trim().isEmpty) return false;
    if (_mode == RecordMode.upload && _selectedFileName == null) return false;
    return true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _agendaController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedAudioExtensions,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.size > _maxAudioSizeBytes) {
      if (mounted) SnackbarUtil.showError(context, 'Ukuran file maksimal 500 MB');
      return;
    }

    setState(() {
      _selectedFileName = file.name;
      _selectedFilePath = file.path;
    });
  }

  void _start() {
    if (!_formKey.currentState!.validate()) return;
    if (_mode == RecordMode.live) {
      context.push('/recording', extra: {
        'title': _titleController.text.trim(),
        'agenda': _agendaController.text.trim(),
      });
    } else {
      context.push('/processing', extra: {
        'title': _titleController.text.trim(),
        'agenda': _agendaController.text.trim(),
        'fileName': _selectedFileName,
        'filePath': _selectedFilePath,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                  Text('Mulai Rapat Baru', style: AppTextStyles.displayMd()),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 24,
                  bottom: AppSpacing.bottomSafe,
                ),
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Rapat
                      AppTextField(
                        label: 'Judul Rapat',
                        hint: 'Contoh: Audit Proses PT Untung Terus',
                        controller: _titleController,
                        isRequired: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Judul rapat wajib diisi' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Agenda
                      AppTextField(
                        label: 'Agenda (opsional)',
                        hint: '1. Review temuan audit Q1\n2. Klarifikasi akuntansi piutang\n3. ...',
                        controller: _agendaController,
                        maxLines: 4,
                        minLines: 4,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Token card
                      _TokenInfoCard(tokenLeft: ref.watch(currentUserProvider)?.tokenLeft ?? 0),
                      const SizedBox(height: AppSpacing.xl),

                      // Mode selector
                      _ModeSelector(
                        selected: _mode,
                        onChanged: (m) => setState(() => _mode = m),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Upload zone (hanya tampil saat mode upload)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _mode == RecordMode.upload
                            ? Column(
                                children: [
                                  _UploadZone(
                                    fileName: _selectedFileName,
                                    onTap: _pickFile,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      // CTA
                      ListenableBuilder(
                        listenable: _titleController,
                        builder: (context, _) => AppButton(
                          label: _mode == RecordMode.live
                              ? 'Mulai Rekam'
                              : 'Upload & Proses',
                          onPressed: _canStart ? _start : null,
                          icon: Icon(
                            _mode == RecordMode.live
                                ? Icons.mic_rounded
                                : Icons.upload_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

// ─── Token Info Card ──────────────────────────────────────────────────────────

class _TokenInfoCard extends StatelessWidget {
  const _TokenInfoCard({required this.tokenLeft});
  final int tokenLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.lg,
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.token_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sisa token bulan ini',
                    style: AppTextStyles.bodySm(c: AppColors.primary)),
                Text('$tokenLeft menit',
                    style: AppTextStyles.bodyMd(
                        c: AppColors.primary, w: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.full,
            ),
            child: Text('Free tier',
                style: AppTextStyles.caption(
                    c: AppColors.textSecondary, w: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Mode Selector ────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onChanged});
  final RecordMode selected;
  final void Function(RecordMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MODE REKAM', style: AppTextStyles.label()),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.borderMedium),
          ),
          child: Row(
            children: [
              Expanded(child: _ModeTab(
                label: 'Live',
                icon: Icons.mic_rounded,
                isActive: selected == RecordMode.live,
                onTap: () => onChanged(RecordMode.live),
              )),
              Expanded(child: _ModeTab(
                label: 'Upload',
                icon: Icons.upload_file_rounded,
                isActive: selected == RecordMode.upload,
                onTap: () => onChanged(RecordMode.upload),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.sm,
          boxShadow: isActive ? AppShadows.buttonPrimary : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.bodyMd(
                    c: isActive ? Colors.white : AppColors.textSecondary,
                    w: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Upload Zone ──────────────────────────────────────────────────────────────

class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.fileName, required this.onTap});
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: fileName != null
                ? AppColors.primary
                : const Color(0x404F46E5),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: fileName != null
            ? Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: AppRadius.md),
                    child: const Icon(Icons.audio_file_rounded,
                        color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fileName!,
                            style: AppTextStyles.bodyMd(w: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        Text('File siap diproses',
                            style: AppTextStyles.bodySm(
                                c: AppColors.success)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                ],
              )
            : Column(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: AppRadius.md),
                    child: const Icon(Icons.upload_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text('Pilih file audio',
                      style: AppTextStyles.bodyMd(w: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('MP3, M4A, WAV, OGG · Maks 500 MB',
                      style: AppTextStyles.bodySm(
                          c: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.md,
                    ),
                    child: Text('Browse File',
                        style: AppTextStyles.bodyMd(
                            c: AppColors.primary,
                            w: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'File akan diproses AI untuk transkripsi.\nDurasi proses ≈ 30% dari durasi audio.',
                    style: AppTextStyles.bodySm(
                        c: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}