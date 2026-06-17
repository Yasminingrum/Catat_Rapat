import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Layar reset password: pengguna memasukkan kode OTP 6-digit yang dikirim
/// ke email (recovery) sekaligus password baru. Verifikasi OTP membuat sesi
/// recovery sementara, lalu password langsung diganti pada sesi tersebut.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  Timer? _cooldownTimer;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier)
        .resetPasswordWithOtp(widget.email, _codeCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (!ok) {
      SnackbarUtil.showError(context, ref.read(authProvider).error ?? s.authResetPasswordFailed);
    }
    // Jika berhasil, authProvider menjadi authenticated dan router akan
    // otomatis redirect ke /home.
  }

  Future<void> _resend(AppStrings s) async {
    final ok = await ref.read(authProvider.notifier).resendPasswordResetOtp(widget.email);
    if (!mounted) return;
    if (ok) {
      SnackbarUtil.showSuccess(context, s.authVerifyCodeResent);
      _startCooldown();
    } else {
      SnackbarUtil.showError(context, s.authVerifyResendFailed);
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final s = ref.watch(appStringsProvider);
    return Scaffold(backgroundColor: AppColors.background,
      body: SafeArea(child: SingleChildScrollView(
        padding: AppSpacing.screenPadding.copyWith(top: 16, bottom: 32),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: () => context.go('/login'),
              child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderMedium)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary))),
          const SizedBox(height: 40),
          Container(width: 56, height: 56,
              decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.lg),
              child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 28)),
          const SizedBox(height: 24),
          Text(s.authResetPasswordTitle, style: AppTextStyles.displayLg()),
          const SizedBox(height: 12),
          Text(s.authResetPasswordBody(widget.email), style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
          const SizedBox(height: 32),
          AppTextField(label: s.authVerifyCodeLabel, hint: s.authVerifyCodeHint, controller: _codeCtrl,
              keyboardType: TextInputType.number, textInputAction: TextInputAction.next,
              validator: s.validateOtpCode),
          const SizedBox(height: 16),
          AppTextField(label: s.authNewPasswordLabel, hint: s.authCreatePasswordHint, controller: _passCtrl,
              isPassword: true, textInputAction: TextInputAction.next, validator: s.validatePassword),
          const SizedBox(height: 16),
          AppTextField(label: s.authConfirmPasswordLabel, hint: s.authConfirmPasswordHint, controller: _confirmCtrl,
              isPassword: true, textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(s),
              validator: s.validateConfirmPassword(() => _passCtrl.text)),
          const SizedBox(height: 32),
          AppButton(label: s.authResetPasswordButton, onPressed: isLoading ? null : () => _submit(s), isLoading: isLoading),
          const SizedBox(height: 24),
          Center(child: _resendCooldown > 0
              ? Text(s.authVerifyResendCooldown(_resendCooldown), style: AppTextStyles.bodyMd(c: AppColors.textTertiary))
              : GestureDetector(onTap: isLoading ? null : () => _resend(s),
                  child: Text(s.authVerifyResend, style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w700)))),
        ])),
      )));
  }
}
