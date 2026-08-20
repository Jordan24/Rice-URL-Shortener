import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/rice_colors.dart';

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
          style: GoogleFonts.lato(
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
          style: GoogleFonts.lato(fontSize: 14, color: RiceColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
            helperText: helperText,
            helperStyle: GoogleFonts.lato(fontSize: 12, color: RiceColors.textSecondary),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF1F5F9) : RiceColors.white,
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
