import 'package:flutter/material.dart';
import '../../../core/constants/branding_colors.dart';
import '../../../core/constants/branding_pack.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/theme/rice_theme.dart';
import 'qr_color_picker_dialog.dart';
import 'qr_contrast_warning.dart';

class QrColorSelector extends StatelessWidget {
  final String fgColorHex;
  final String bgColorHex;
  final BrandingPackType brandingPack;
  final ValueChanged<String> onFgColorChanged;
  final ValueChanged<String> onBgColorChanged;

  const QrColorSelector({
    super.key,
    required this.fgColorHex,
    required this.bgColorHex,
    this.brandingPack = BrandingPackType.university,
    required this.onFgColorChanged,
    required this.onBgColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fgPresets = BrandingColors.getFgPresets(brandingPack);
    final bgPresets = BrandingColors.getBgPresets(brandingPack);
    final fgTitle = brandingPack == BrandingPackType.university
        ? "Foreground Color (Rice Brand)"
        : "Foreground Color (${brandingPack.shortName})";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foreground Section
        _buildColorSection(
          context: context,
          title: fgTitle,
          currentHex: fgColorHex,
          presets: fgPresets,
          onPresetSelected: onFgColorChanged,
          onCustomTap: () => showQrColorPickerDialog(
            context: context,
            currentHex: fgColorHex,
            onSelected: onFgColorChanged,
            title: "Custom Foreground Color",
          ),
        ),

        const SizedBox(height: 16),

        // Background Section
        _buildColorSection(
          context: context,
          title: "Background Color",
          currentHex: bgColorHex,
          presets: bgPresets,
          onPresetSelected: onBgColorChanged,
          onCustomTap: () => showQrColorPickerDialog(
            context: context,
            currentHex: bgColorHex,
            onSelected: onBgColorChanged,
            title: "Custom Background Color",
          ),
        ),

        // Real-time contrast validation warning
        QrContrastWarning(
          fgColorHex: fgColorHex,
          bgColorHex: bgColorHex,
        ),
      ],
    );
  }

  Widget _buildColorSection({
    required BuildContext context,
    required String title,
    required String currentHex,
    required List<RiceColorPreset> presets,
    required ValueChanged<String> onPresetSelected,
    required VoidCallback onCustomTap,
  }) {
    final normCurrent = currentHex.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: RiceTheme.body(fontSize: 13, fontWeight: FontWeight.w600, color: RiceColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              normCurrent,
              style: RiceTheme.body(fontSize: 12, fontWeight: FontWeight.w500, color: RiceColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...presets.map((preset) {
              final isSelected = normCurrent == preset.hex.toUpperCase() ||
                  (preset.hex.length == 7 && normCurrent == '#FF${preset.hex.substring(1)}'.toUpperCase());

              final isTrans = preset.color.a == 0;

              return Tooltip(
                message: preset.name,
                child: InkWell(
                  onTap: () => onPresetSelected(preset.hex),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: preset.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? RiceColors.riceBlue : RiceColors.borderLight,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: RiceColors.riceBlue.withValues(alpha: 0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isTrans
                        ? const Center(
                            child: Icon(Icons.close, size: 16, color: RiceColors.textSecondary),
                          )
                        : isSelected
                            ? Center(
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: preset.color.computeLuminance() > 0.5 ? RiceColors.darkGray : Colors.white,
                                ),
                              )
                            : null,
                  ),
                ),
              );
            }),

            // Custom Color Picker Button
            Tooltip(
              message: "Custom Color",
              child: InkWell(
                onTap: onCustomTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: RiceColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: RiceColors.borderLight, width: 1),
                  ),
                  child: const Center(
                    child: Icon(Icons.colorize_rounded, size: 16, color: RiceColors.textPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
