import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({super.key, required this.label, required this.hint,
    this.controller, this.isPassword = false, this.keyboardType,
    this.validator, this.onChanged, this.maxLines = 1, this.minLines,
    this.isRequired = false, this.suffixIcon, this.prefixIcon,
    this.autofocus = false, this.textInputAction, this.onFieldSubmitted,
    this.enabled = true, this.initialValue});

  final String label, hint;
  final TextEditingController? controller;
  final bool isPassword, isRequired, autofocus, enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final int? minLines;
  final Widget? suffixIcon, prefixIcon;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? initialValue;

  @override State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text(widget.label.toUpperCase(), style: AppTextStyles.label()),
        if (widget.isRequired) Text(' *', style: AppTextStyles.label(c: AppColors.error)),
      ]),
      const SizedBox(height: 8),
      TextFormField(
        controller: widget.controller,
        initialValue: widget.initialValue,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onChanged: widget.onChanged,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        minLines: widget.minLines,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        enabled: widget.enabled,
        style: AppTextStyles.bodyMd(),
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textTertiary, size: 18))
              : widget.suffixIcon,
        ),
      ),
    ],
  );
}
