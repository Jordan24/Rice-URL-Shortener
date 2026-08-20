import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../data/models/qr_config.dart';

class QrStyleSelector extends StatelessWidget {
  final QrStyle selectedStyle;
  final ValueChanged<QrStyle> onStyleChanged;

  const QrStyleSelector({
    super.key,
    required this.selectedStyle,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Module Shape & Style",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RiceColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: QrStyle.values.map((style) {
            final isSelected = style == selectedStyle;
            IconData icon;
            switch (style) {
              case QrStyle.square:
                icon = Icons.crop_square_rounded;
                break;
              case QrStyle.rounded:
                icon = Icons.rounded_corner_rounded;
                break;
              case QrStyle.dots:
                icon = Icons.blur_on_rounded;
                break;
            }

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onStyleChanged(style),
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? RiceColors.riceBlue.withValues(alpha: 0.08) : RiceColors.white,
                      border: Border.all(
                        color: isSelected ? RiceColors.riceBlue : RiceColors.borderLight,
                        width: isSelected ? 1.8 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 22, color: isSelected ? RiceColors.riceBlue : RiceColors.textSecondary),
                        const SizedBox(height: 4),
                        Text(
                          style.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? RiceColors.riceBlue : RiceColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
