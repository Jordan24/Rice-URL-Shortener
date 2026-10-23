import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/theme/rice_theme.dart';
import '../../../core/utils/qr_contrast_helper.dart';

/// Accessible warning widget displayed when chosen QR code colors
/// violate ISO/IEC 18004 contrast or polarity standards.
class QrContrastWarning extends StatelessWidget {
  final String fgColorHex;
  final String bgColorHex;
  final EdgeInsetsGeometry margin;

  const QrContrastWarning({
    super.key,
    required this.fgColorHex,
    required this.bgColorHex,
    this.margin = const EdgeInsets.only(top: 12),
  });

  @override
  Widget build(BuildContext context) {
    final result = QrContrastHelper.validateContrast(
      fgHex: fgColorHex,
      bgHex: bgColorHex,
    );

    if (result.isStandardCompliant) {
      return const SizedBox.shrink();
    }

    final isCritical = result.severity == QrContrastSeverity.critical;
    final primaryColor = isCritical ? RiceColors.brickRed : const Color(0xFFB87000);
    final bgColor = isCritical
        ? RiceColors.brickRed.withValues(alpha: 0.08)
        : RiceColors.laurelGold.withValues(alpha: 0.14);
    final borderColor = isCritical
        ? RiceColors.brickRed.withValues(alpha: 0.40)
        : RiceColors.laurelGold.withValues(alpha: 0.60);
    final iconData = isCritical ? Icons.error_outline_rounded : Icons.warning_amber_rounded;

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(iconData, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.title,
                  style: RiceTheme.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildBadge(result, primaryColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.message,
            style: RiceTheme.body(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: RiceColors.textPrimary,
              height: 1.35,
            ),
          ),
          if (result.recommendation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 14, color: primaryColor),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    result.recommendation,
                    style: RiceTheme.body(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(QrContrastResult result, Color primaryColor) {
    String label;
    if (result.status == QrContrastStatus.inverted) {
      label = "Inverted";
    } else if (result.isTransparentBg) {
      label = "Transparent BG";
    } else {
      label = "${result.formattedRatio} (Min 4.0:1)";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: RiceTheme.body(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
      ),
    );
  }
}
