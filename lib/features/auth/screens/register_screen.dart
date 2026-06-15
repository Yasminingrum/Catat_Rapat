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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier)
        .register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (!ok) {
      SnackbarUtil.showError(context, authState.error ?? s.authRegisterFailed);
      return;
    }
    if (authState.message != null) {
      // Registrasi berhasil tapi menunggu verifikasi email.
      SnackbarUtil.showSuccess(context, authState.message!);
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final s = ref.watch(appStringsProvider);
    return Scaffold(backgroundColor: AppColors.background,
      body: SafeArea(child: SingleChildScrollView(
        padding: AppSpacing.screenPadding.copyWith(top: 16, bottom: 32),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: () => context.pop(),
              child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderMedium)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary))),
          const SizedBox(height: 24),
          const Center(child: AuthLogo()),
          const SizedBox(height: 24),
          Center(child: Text(s.authRegisterTitle, style: AppTextStyles.displayLg())),
          const SizedBox(height: 8),
          Center(child: Text(s.authTaglineFull, style: AppTextStyles.bodyMd(c: AppColors.textSecondary))),
          const SizedBox(height: 40),
          AppTextField(label: s.authFullNameLabel, hint: s.authFullNameHint, controller: _nameCtrl,
              isRequired: true, textInputAction: TextInputAction.next,
              validator: s.validateRequired(s.authFieldNama)),
          const SizedBox(height: 16),
          AppTextField(label: s.authEmailLabel, hint: 'nama@email.com', controller: _emailCtrl,
              isRequired: true, keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next, validator: s.validateEmail),
          const SizedBox(height: 16),
          AppTextField(label: s.authPasswordLabel, hint: s.authCreatePasswordHint, controller: _passCtrl,
              isPassword: true, isRequired: true, textInputAction: TextInputAction.next,
              validator: s.validatePassword),
          const SizedBox(height: 16),
          AppTextField(label: s.authConfirmPasswordLabel, hint: s.authConfirmPasswordHint, controller: _confirmCtrl,
              isPassword: true, isRequired: true, textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(s),
              validator: s.validateConfirmPassword(_passCtrl.text)),
          const SizedBox(height: 32),
          AppButton(label: s.authRegisterButton, onPressed: isLoading ? null : () => _register(s), isLoading: isLoading),
          const SizedBox(height: 24),
          Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s.authHaveAccount, style: AppTextStyles.bodyMd(c: AppColors.textSecondary)),
            GestureDetector(onTap: () => context.go('/login'),
                child: Text(s.authLoginNow, style: AppTextStyles.bodyMd(c: AppColors.primary, w: FontWeight.w700))),
          ])),
        ])),
      )));
  }
}
