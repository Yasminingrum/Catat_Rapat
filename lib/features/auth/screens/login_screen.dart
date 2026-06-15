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
import '../widgets/auth_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  @override void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!ok && mounted) SnackbarUtil.showError(context, ref.read(authProvider).error ?? s.authLoginFailed);
  }

  Future<void> _loginWithGoogle(AppStrings s) async {
    final ok = await ref.read(authProvider.notifier).loginWithGoogle();
    if (!ok && mounted) SnackbarUtil.showError(context, ref.read(authProvider).error ?? s.authLoginGoogleFailed);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final s = ref.watch(appStringsProvider);
    return Scaffold(backgroundColor: AppColors.background,
      body: SafeArea(child: SingleChildScrollView(
        padding: AppSpacing.screenPadding.copyWith(top: 48, bottom: 32),
        child: Form(key: _formKey, child: Column(children: [
          const AuthLogo(),
          const SizedBox(height: 24),
          Text(s.authLoginTitle, style: AppTextStyles.displayLg(), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(s.authTagline, style: AppTextStyles.bodyMd(c: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 40),
          AppTextField(label: s.authEmailLabel, hint: 'nama@email.com', controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
              validator: s.validateEmail),
          const SizedBox(height: 16),
          AppTextField(label: s.authPasswordLabel, hint: '••••••••', controller: _passCtrl,
              isPassword: true, textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(s), validator: s.validatePassword),
          Align(alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => context.push('/forgot-password'),
                  child: Text(s.authForgotPassword, style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w500)))),
          const SizedBox(height: 16),
          AppButton(label: s.authLoginButton, onPressed: isLoading ? null : () => _login(s), isLoading: isLoading),
          const SizedBox(height: 24),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(s.authOrContinueWith, style: AppTextStyles.bodySm(c: AppColors.textTertiary))),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
          _GoogleButton(s: s, onTap: isLoading ? null : () => _loginWithGoogle(s)),
          const SizedBox(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s.authNoAccount, style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
            GestureDetector(onTap: () => context.push('/register'),
                child: Text(s.authRegisterNow, style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w700))),
          ]),
        ])),
      )));
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.s, required this.onTap});
  final AppStrings s;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.borderMedium)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 20, height: 20, decoration: const BoxDecoration(
            color: Color(0xFFF1F3F4), borderRadius: AppRadius.full),
            child: Center(child: Text('G', style: AppTextStyles.bodySm(c: const Color(0xFF4285F4), w: FontWeight.w700)))),
        const SizedBox(width: 12),
        Text(s.authGoogleSignIn, style: AppTextStyles.bodyMd(w: FontWeight.w500)),
      ]),
    ),
  );
}
