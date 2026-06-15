import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../widgets/option_picker_sheet.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final s = ref.watch(appStringsProvider);
    final tokenPct = user?.tokenPercent ?? 0.64;
    final tokenColor = tokenPct > 0.4 ? AppColors.success : tokenPct > 0.15 ? AppColors.warning : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(children: [
        Container(color: AppColors.surface, padding: const EdgeInsets.fromLTRB(24,16,24,16),
            child: Text(s.profilTitle, style: AppTextStyles.displayMd())),
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
            Text(user?.name ?? s.profilDefaultUser, style: AppTextStyles.displayMd()),
            Text(user?.email ?? '', style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // Akun & Keamanan
            _SectionHeader(s.profilSectionAccount),
            _MenuItem(s.profilChangeName, Icons.person_outline_rounded, onTap: () => _editName(context, ref, user, s)),
            _MenuItem(s.profilChangeEmail, Icons.email_outlined, onTap: () => _editEmail(context, ref, user, s)),
            _MenuItem(s.profilChangePassword, Icons.lock_outline_rounded, onTap: () => _changePassword(context, ref, s)),
            _MenuItem(s.profilDeleteAccount, Icons.delete_outline_rounded,
                textColor: AppColors.error, onTap: (){}),
            const SizedBox(height: 16),

            // Preferensi
            _SectionHeader(s.profilSectionPreferences),
            _MenuItemWithValue(s.profilLanguage, Icons.language_rounded, settings.language.label,
                onTap: () => _pickLanguage(context, ref, settings.language, s)),
            _MenuItemWithValue(s.profilExportFormat, Icons.picture_as_pdf_outlined, settings.exportFormat.label,
                onTap: () => _pickExportFormat(context, ref, settings.exportFormat, s)),
            _MenuItemWithValue(s.profilRecordingQuality, Icons.mic_outlined, s.recordingQualityLabel(settings.recordingQuality),
                onTap: () => _pickRecordingQuality(context, ref, settings.recordingQuality, s)),
            const SizedBox(height: 16),

            // Notifikasi
            _SectionHeader(s.profilSectionNotifications),
            _MenuItemSwitch(s.profilNotifActionReminder, Icons.notifications_outlined,
                settings.notifActionReminder, (v) async {
              await ref.read(settingsProvider.notifier).setNotifActionReminder(v);
              if (v) {
                await NotificationService.instance.requestPermission();
              } else {
                await NotificationService.instance.cancelAllScheduled();
              }
            }),
            _MenuItemSwitch(s.profilNotifSummaryReady, Icons.check_circle_outline_rounded,
                settings.notifSummaryReady, (v) async {
              await ref.read(settingsProvider.notifier).setNotifSummaryReady(v);
              if (v) {
                await NotificationService.instance.requestPermission();
              }
            }),
            const SizedBox(height: 16),

            // Penyimpanan
            _SectionHeader(s.profilSectionStorage),
            _MenuItemWithValue(s.profilRetention, Icons.storage_outlined, s.retentionPeriodLabel(settings.retention),
                onTap: () => _pickRetention(context, ref, settings.retention, s)),
            _MenuItem(s.profilDeleteAllData, Icons.delete_forever_outlined,
                textColor: AppColors.error, onTap: (){}),
            const SizedBox(height: 16),

            // Langganan + Token
            _SectionHeader(s.profilSectionSubscription),
            Container(padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.lg,
                  border: Border.all(color: AppColors.borderLight), boxShadow: AppShadows.card),
              child: Column(children: [
                Row(children: [
                  Container(width:32, height:32, decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.md),
                      child: const Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size:18)),
                  const SizedBox(width:10),
                  Text(_planLabel(user?.plan ?? UserPlan.free, s), style: AppTextStyles.displayXs()),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
                      decoration: const BoxDecoration(color: AppColors.successLight, borderRadius: AppRadius.full),
                      child: Text(s.profilActive, style: AppTextStyles.caption(c: AppColors.success, w: FontWeight.w600))),
                ]),
                const SizedBox(height:12),
                Row(children: [
                  Text(s.profilTokenRemaining, style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
                  const Spacer(),
                  Text('${user?.tokenLeft ?? 3200} / ${user?.tokenTotal ?? 5000}',
                      style: AppTextStyles.bodyMd(c: tokenColor, w: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: AppRadius.full, child: LinearProgressIndicator(
                    value: 1 - tokenPct, minHeight: 6, backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(tokenColor))),
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerRight, child: Text(s.profilResetDate,
                    style: AppTextStyles.caption(c: AppColors.textTertiary))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: _GradientButton(
                    label: s.profilUpgrade, onTap: () => context.push('/upgrade'))),
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
                  Text(s.profilLogout, style: AppTextStyles.bodyMd(c: AppColors.error, w: FontWeight.w600)),
                ]))),
          ]))),
      ])),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

String _planLabel(UserPlan plan, AppStrings s) => switch (plan) {
  UserPlan.free => s.profilPlanFree,
  UserPlan.pro => s.profilPlanPro,
  UserPlan.business => s.profilPlanBusiness,
};

Future<void> _editName(BuildContext context, WidgetRef ref, AppUser? user, AppStrings s) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _EditNameDialog(initialName: user?.name ?? '', s: s),
  );
  if (!context.mounted) return;
  if (result == true) {
    SnackbarUtil.showSuccess(context, s.profilNameUpdated);
  } else if (result == false) {
    SnackbarUtil.showError(context, s.profilNameUpdateFailed);
  }
}

Future<void> _pickLanguage(BuildContext context, WidgetRef ref, AppLanguage current, AppStrings s) async {
  final result = await showOptionPickerSheet<AppLanguage>(context,
      title: s.profilLanguagePickerTitle, options: AppLanguage.values, selected: current,
      labelOf: (v) => v.label);
  if (result != null) ref.read(settingsProvider.notifier).setLanguage(result);
}

Future<void> _pickExportFormat(BuildContext context, WidgetRef ref, ExportFormat current, AppStrings s) async {
  final result = await showOptionPickerSheet<ExportFormat>(context,
      title: s.profilExportFormat, options: ExportFormat.values, selected: current,
      labelOf: (v) => v.label);
  if (result != null) ref.read(settingsProvider.notifier).setExportFormat(result);
}

Future<void> _pickRecordingQuality(BuildContext context, WidgetRef ref, RecordingQuality current, AppStrings s) async {
  final result = await showOptionPickerSheet<RecordingQuality>(context,
      title: s.profilRecordingQuality, options: RecordingQuality.values, selected: current,
      labelOf: (v) => s.recordingQualityLabel(v));
  if (result != null) ref.read(settingsProvider.notifier).setRecordingQuality(result);
}

Future<void> _pickRetention(BuildContext context, WidgetRef ref, RetentionPeriod current, AppStrings s) async {
  final result = await showOptionPickerSheet<RetentionPeriod>(context,
      title: s.profilRetention, options: RetentionPeriod.values, selected: current,
      labelOf: (v) => s.retentionPeriodLabel(v));
  if (result != null) ref.read(settingsProvider.notifier).setRetention(result);
}

Future<void> _editEmail(BuildContext context, WidgetRef ref, AppUser? user, AppStrings s) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _EditEmailDialog(initialEmail: user?.email ?? '', s: s),
  );
  if (!context.mounted) return;
  if (result == true) {
    SnackbarUtil.showSuccess(context, s.profilEmailConfirmSent);
  } else if (result == false) {
    SnackbarUtil.showError(context, s.profilEmailUpdateFailed);
  }
}

Future<void> _changePassword(BuildContext context, WidgetRef ref, AppStrings s) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _ChangePasswordDialog(s: s),
  );
  if (!context.mounted) return;
  if (result == true) {
    SnackbarUtil.showSuccess(context, s.profilPasswordUpdated);
  } else if (result == false) {
    SnackbarUtil.showError(context, s.profilPasswordUpdateFailed);
  }
}

class _EditNameDialog extends ConsumerStatefulWidget {
  const _EditNameDialog({required this.initialName, required this.s});
  final String initialName;
  final AppStrings s;
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
    title: Text(widget.s.profilChangeNameTitle, style: AppTextStyles.displaySm()),
    content: TextField(
      controller: _ctrl,
      autofocus: true,
      decoration: InputDecoration(hintText: widget.s.profilFullNameHint),
    ),
    actions: [
      TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(widget.s.commonCancel)),
      TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.s.commonSave)),
    ],
  );
}

class _EditEmailDialog extends ConsumerStatefulWidget {
  const _EditEmailDialog({required this.initialEmail, required this.s});
  final String initialEmail;
  final AppStrings s;
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
      setState(() => _error = widget.s.profilInvalidEmail);
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
    title: Text(widget.s.profilChangeEmailTitle, style: AppTextStyles.displaySm()),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(hintText: widget.s.profilNewEmailHint),
      ),
      const SizedBox(height: 8),
      Text(widget.s.profilEmailConfirmNotice, style: AppTextStyles.caption()),
      if (_error != null) ...[
        const SizedBox(height: 4),
        Text(_error!, style: AppTextStyles.caption(c: AppColors.error)),
      ],
    ]),
    actions: [
      TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(widget.s.commonCancel)),
      TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.s.profilSend)),
    ],
  );
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog({required this.s});
  final AppStrings s;
  @override ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pass = _passCtrl.text;
    if (pass.length < 8) {
      setState(() => _error = widget.s.validationPasswordMinLength);
      return;
    }
    if (pass != _confirmCtrl.text) {
      setState(() => _error = widget.s.validationPasswordMismatch);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await ref.read(authProvider.notifier).changePassword(pass);
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.s.profilChangePasswordTitle, style: AppTextStyles.displaySm()),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _passCtrl,
        autofocus: true,
        obscureText: true,
        decoration: InputDecoration(hintText: widget.s.authNewPasswordLabel),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _confirmCtrl,
        obscureText: true,
        decoration: InputDecoration(hintText: widget.s.authConfirmPasswordLabel),
      ),
      if (_error != null) ...[
        const SizedBox(height: 4),
        Text(_error!, style: AppTextStyles.caption(c: AppColors.error)),
      ],
    ]),
    actions: [
      TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(widget.s.commonCancel)),
      TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.s.commonSave)),
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
  const _MenuItemWithValue(this.label, this.icon, this.value, {this.onTap});
  final String label, value; final IconData icon; final VoidCallback? onTap;
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical:14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
      child: Row(children: [
        Icon(icon, size:20, color: AppColors.textSecondary),
        const SizedBox(width:12),
        Expanded(child: Text(label, style: AppTextStyles.bodyMd())),
        Text(value, style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w500)),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
        ],
      ])));
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
