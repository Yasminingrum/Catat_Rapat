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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await ref.read(authProvider.notifier).sendPasswordResetOtp(email);
    if (!mounted) return;
    if (ok) {
      context.push('/reset-password', extra: {'email': email});
    } else {
      SnackbarUtil.showErrorOnMessenger(messenger, ref.read(authProvider).error ?? s.authResetPasswordSendFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
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
            textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _send(s),
            validator: s.validateEmail)),
        const SizedBox(height: 32),
        AppButton(label: s.authResetPasswordButton, onPressed: isLoading ? null : () => _send(s), isLoading: isLoading),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(s.authNoAccount, style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
          GestureDetector(onTap: () => context.push('/register'),
              child: Text(s.authRegisterNow, style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w700))),
        ]),
      ]),
    )));
  }
}
