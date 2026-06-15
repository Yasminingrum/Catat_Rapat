import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false, _sent = false;

  @override void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: Supabase resetPasswordForEmail
    setState(() { _loading = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(backgroundColor: AppColors.background,
    body: SafeArea(child: SingleChildScrollView(
      padding: AppSpacing.screenPadding.copyWith(top: 16, bottom: 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(onTap: () => context.pop(),
            child: Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderMedium)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary))),
        const SizedBox(height: 40),
        if (_sent) ...[
          Center(child: Container(width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.successLight, borderRadius: AppRadius.full),
              child: const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 32))),
          const SizedBox(height: 24),
          Center(child: Text(s.authEmailSentTitle, style: AppTextStyles.displayLg())),
          const SizedBox(height: 8),
          Center(child: Text(s.authEmailSentBody(_emailCtrl.text),
              style: AppTextStyles.bodyMd(c: AppColors.textSecondary), textAlign: TextAlign.center)),
          const SizedBox(height: 40),
          AppButton(label: s.authBackToLogin, onPressed: () => context.go('/login')),
        ] else ...[
          Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.lg),
              child: const Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 28)),
          const SizedBox(height: 24),
          Text(s.authForgotPasswordTitle, style: AppTextStyles.displayLg()),
          const SizedBox(height: 12),
          Text(s.authForgotPasswordBody,
              style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Form(key: _formKey, child: AppTextField(label: s.authEmailLabel, hint: 'nama@email.com',
              controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _send(),
              validator: s.validateEmail)),
          const SizedBox(height: 32),
          AppButton(label: s.authResetPasswordButton, onPressed: _loading ? null : _send, isLoading: _loading),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s.authNoAccount, style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
            GestureDetector(onTap: () => context.push('/register'),
                child: Text(s.authRegisterNow, style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w700))),
          ]),
        ],
      ]),
    )));
  }
}
