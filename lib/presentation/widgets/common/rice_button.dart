import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';

enum RiceButtonVariant { primary, secondary, outline, danger }

class RiceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final RiceButtonVariant variant;
  final bool isLoading;
  final double? width;

  const RiceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = RiceButtonVariant.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case RiceButtonVariant.primary:
        bg = RiceColors.riceBlue;
        fg = RiceColors.white;
        break;
      case RiceButtonVariant.secondary:
        bg = RiceColors.laurelGold;
        fg = RiceColors.darkBlue;
        break;
      case RiceButtonVariant.outline:
        bg = Colors.transparent;
        fg = RiceColors.riceBlue;
        border = const BorderSide(color: RiceColors.riceBlue, width: 1.5);
        break;
      case RiceButtonVariant.danger:
        bg = RiceColors.errorRed;
        fg = RiceColors.white;
        break;
    }

    Widget child;
    if (isLoading) {
      child = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      );
    } else {
      child = Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14));
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      side: border,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      elevation: 0,
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: child,
        ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: child,
    );
  }
}
