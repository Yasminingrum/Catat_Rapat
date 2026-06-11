import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/app_bottom_nav.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tokenPct = user?.tokenPercent ?? 0.64;
    final tokenColor = tokenPct > 0.4 ? AppColors.success : tokenPct > 0.15 ? AppColors.warning : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(24,16,24,16),
            child: Text('Profil & Pengaturan', style: AppTextStyles.displayMd())),
        const Divider(height:1),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24,24,24,96),
          child: Column(children: [
            // Avatar + name
            Container(width:80, height:80,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: Center(child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: AppTextStyles.displayLg(c: Colors.white)))),
            const SizedBox(height:12),
            Text(user?.name ?? 'Pengguna', style: AppTextStyles.displayMd()),
            Text(user?.email ?? '', style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // Akun & Keamanan
            const _SectionHeader('AKUN & KEAMANAN'),
            _MenuItem('Ganti Nama', Icons.person_outline_rounded, onTap: () => _editName(context, ref, user)),
            _MenuItem('Ganti Email', Icons.email_outlined, onTap: () => _editEmail(context, ref, user)),
            _MenuItem('Ganti Password', Icons.lock_outline_rounded, onTap: (){}),
            _MenuItem('Hapus Akun', Icons.delete_outline_rounded,
                textColor: AppColors.error, onTap: (){}),
            const SizedBox(height: 16),

            // Preferensi
            const _SectionHeader('PREFERENSI APLIKASI'),
            const _MenuItemWithValue('Bahasa Output Notula', Icons.language_rounded, 'Bahasa Indonesia'),
            const _MenuItemWithValue('Format Ekspor Default', Icons.picture_as_pdf_outlined, 'PDF'),
            const _MenuItemWithValue('Kualitas Rekaman', Icons.mic_outlined, 'Standar (16kHz)'),
            const SizedBox(height: 16),

            // Notifikasi
            const _SectionHeader('NOTIFIKASI'),
            _MenuItemSwitch('Reminder Action Item', Icons.notifications_outlined, true, (v){}),
            _MenuItemSwitch('Notifikasi Ringkasan Selesai', Icons.check_circle_outline_rounded, true, (v){}),
            const SizedBox(height: 16),

            // Penyimpanan
            const _SectionHeader('PENYIMPANAN & DATA'),
            const _MenuItemWithValue('Retensi Rekaman', Icons.storage_outlined, '90 hari'),
            _MenuItem('Hapus Semua Data Rapat', Icons.delete_forever_outlined,
                textColor: AppColors.error, onTap: (){}),
            const SizedBox(height: 16),

            // Langganan + Token
            const _SectionHeader('LANGGANAN'),
            Container(padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
                  border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
              child: Column(children: [
                Row(children: [
                  Container(width:32, height:32, decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.md),
                      child: const Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size:18)),
                  const SizedBox(width:10),
                  Text(_planLabel(user?.plan ?? UserPlan.free), style: AppTextStyles.displayXs()),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
                      decoration: const BoxDecoration(color: AppColors.successLight, borderRadius: AppRadius.full),
                      child: Text('Aktif', style: AppTextStyles.caption(c: AppColors.success, w: FontWeight.w600))),
                ]),
                const SizedBox(height:12),
                Row(children: [
                  Text('Token AI tersisa', style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
                  const Spacer(),
                  Text('${user?.tokenLeft ?? 3200} / ${user?.tokenTotal ?? 5000}',
                      style: AppTextStyles.bodyMd(c: tokenColor, w: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: AppRadius.full, child: LinearProgressIndicator(
                    value: 1 - tokenPct, minHeight: 6, backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(tokenColor))),
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerRight, child: Text('Reset tanggal 1 setiap bulan',
                    style: AppTextStyles.caption(c: AppColors.textTertiary))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: _GradientButton(
                    label: '⚡ Upgrade ke Premium', onTap: () => context.push('/upgrade'))),
              ])),
            const SizedBox(height: 16),

            // Logout
            GestureDetector(
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              child: Container(padding: const EdgeInsets.symmetric(vertical:16),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.logout_rounded, color: AppColors.error, size:20),
                  const SizedBox(width:8),
                  Text('Keluar', style: AppTextStyles.bodyMd(c: AppColors.error, w: FontWeight.w600)),
                ]))),
          ]))),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

String _planLabel(UserPlan plan) => switch (plan) {
  UserPlan.free => 'Paket Gratis',
  UserPlan.pro => 'Paket Pro',
  UserPlan.business => 'Paket Business',
};

Future<void> _editName(BuildContext context, WidgetRef ref, AppUser? user) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _EditNameDialog(initialName: user?.name ?? ''),
  );
  if (!context.mounted) return;
  if (result == true) {
    SnackbarUtil.showSuccess(context, 'Nama berhasil diperbarui');
  } else if (result == false) {
    SnackbarUtil.showError(context, 'Gagal memperbarui nama');
  }
}

Future<void> _editEmail(BuildContext context, WidgetRef ref, AppUser? user) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _EditEmailDialog(initialEmail: user?.email ?? ''),
  );
  if (!context.mounted) return;
  if (result == true) {
    SnackbarUtil.showSuccess(context, 'Tautan konfirmasi telah dikirim ke email baru');
  } else if (result == false) {
    SnackbarUtil.showError(context, 'Gagal mengubah email');
  }
}

class _EditNameDialog extends ConsumerStatefulWidget {
  const _EditNameDialog({required this.initialName});
  final String initialName;
  @override ConsumerState<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends ConsumerState<_EditNameDialog> {
  late final _ctrl = TextEditingController(text: widget.initialName);
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final ok = await ref.read(authProvider.notifier).updateProfile(name: name);
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Ganti Nama', style: AppTextStyles.displaySm()),
    content: TextField(
      controller: _ctrl,
      autofocus: true,
      decoration: const InputDecoration(hintText: 'Nama lengkap'),
    ),
    actions: [
      TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal')),
      TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan')),
    ],
  );
}

class _EditEmailDialog extends ConsumerStatefulWidget {
  const _EditEmailDialog({required this.initialEmail});
  final String initialEmail;
  @override ConsumerState<_EditEmailDialog> createState() => _EditEmailDialogState();
}

class _EditEmailDialogState extends ConsumerState<_EditEmailDialog> {
  late final _ctrl = TextEditingController(text: widget.initialEmail);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _ctrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Email tidak valid');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await ref.read(authProvider.notifier).updateEmail(email);
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Ganti Email', style: AppTextStyles.displaySm()),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(hintText: 'Alamat email baru'),
      ),
      const SizedBox(height: 8),
      Text('Tautan konfirmasi akan dikirim ke email baru.', style: AppTextStyles.caption()),
      if (_error != null) ...[
        const SizedBox(height: 4),
        Text(_error!, style: AppTextStyles.caption(c: AppColors.error)),
      ],
    ]),
    actions: [
      TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal')),
      TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Kirim')),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom:8),
    child: Align(alignment: Alignment.centerLeft,
        child: Text(title, style: AppTextStyles.label())));
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(this.label, this.icon, {required this.onTap, this.textColor});
  final String label; final IconData icon; final VoidCallback onTap; final Color? textColor;
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Container(padding: const EdgeInsets.symmetric(vertical:14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
      child: Row(children: [
        Icon(icon, size:20, color: textColor ?? AppColors.textSecondary),
        const SizedBox(width:12),
        Expanded(child: Text(label, style: AppTextStyles.bodyMd(c: textColor ?? AppColors.textPrimary))),
        Icon(Icons.chevron_right_rounded, size:18, color: textColor ?? AppColors.textTertiary),
      ])));
}

class _MenuItemWithValue extends StatelessWidget {
  const _MenuItemWithValue(this.label, this.icon, this.value);
  final String label, value; final IconData icon;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical:14),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
    child: Row(children: [
      Icon(icon, size:20, color: AppColors.textSecondary),
      const SizedBox(width:12),
      Expanded(child: Text(label, style: AppTextStyles.bodyMd())),
      Text(value, style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w500)),
    ]));
}

class _MenuItemSwitch extends StatelessWidget {
  const _MenuItemSwitch(this.label, this.icon, this.value, this.onChanged);
  final String label; final IconData icon; final bool value; final void Function(bool) onChanged;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical:10),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
    child: Row(children: [
      Icon(icon, size:20, color: AppColors.textSecondary),
      const SizedBox(width:12),
      Expanded(child: Text(label, style: AppTextStyles.bodyMd())),
      Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
    ]));
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});
  final String label; final VoidCallback onTap;
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical:14),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: AppRadius.md,
          boxShadow: AppShadows.buttonPrimary),
      child: Center(child: Text(label, style: AppTextStyles.bodyMd(c: Colors.white, w: FontWeight.w700)))));
}
