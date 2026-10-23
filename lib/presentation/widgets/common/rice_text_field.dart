import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/theme/rice_theme.dart';

class RiceTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final int maxLines;

  const RiceTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.prefix,
    this.suffix,
    this.readOnly = false,
    this.onChanged,
    this.helperText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: RiceTheme.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: RiceColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          readOnly: readOnly,
          onChanged: onChanged,
          maxLines: maxLines,
          style: RiceTheme.body(fontSize: 14, color: RiceColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: RiceTheme.body(fontSize: 14, color: RiceColors.textSecondary.withValues(alpha: 0.7)),
            prefixIcon: prefix,
            suffixIcon: suffix,
            helperText: helperText,
            helperStyle: RiceTheme.body(fontSize: 12, color: RiceColors.textSecondary),
            errorStyle: RiceTheme.body(fontSize: 12, color: RiceColors.errorRed),
            filled: true,
            fillColor: readOnly ? RiceColors.lightGray : RiceColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: RiceColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: RiceColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: RiceColors.riceBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
