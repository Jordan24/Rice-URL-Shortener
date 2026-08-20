import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../core/constants/rice_colors.dart';

class QrColorSelector extends StatelessWidget {
  final String fgColorHex;
  final String bgColorHex;
  final ValueChanged<String> onFgColorChanged;
  final ValueChanged<String> onBgColorChanged;

  const QrColorSelector({
    super.key,
    required this.fgColorHex,
    required this.bgColorHex,
    required this.onFgColorChanged,
    required this.onBgColorChanged,
  });

  void _showColorPickerDialog(BuildContext context, String currentHex, ValueChanged<String> onSelected, String title) {
    Color pickerColor = _parseColor(currentHex);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (c) => pickerColor = c,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: true,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final hex = "#${pickerColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}";
              onSelected(hex);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: RiceColors.riceBlue, foregroundColor: Colors.white),
            child: const Text("Select"),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    var cleaned = hex.replaceAll("#", "").trim();
    if (cleaned.length == 6) cleaned = "FF$cleaned";
    if (cleaned.length == 8) {
      final val = int.tryParse(cleaned, radix: 16);
      if (val != null) return Color(val);
    }
    return RiceColors.riceBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foreground Section
        _buildColorSection(
          context: context,
          title: "Foreground Color (Rice Brand)",
          currentHex: fgColorHex,
          presets: RiceColors.fgPresets,
          onPresetSelected: onFgColorChanged,
          onCustomTap: () => _showColorPickerDialog(context, fgColorHex, onFgColorChanged, "Custom Foreground Color"),
        ),

        const SizedBox(height: 16),

        // Background Section
        _buildColorSection(
          context: context,
          title: "Background Color",
          currentHex: bgColorHex,
          presets: RiceColors.bgPresets,
          onPresetSelected: onBgColorChanged,
          onCustomTap: () => _showColorPickerDialog(context, bgColorHex, onBgColorChanged, "Custom Background Color"),
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
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RiceColors.textPrimary),
            ),
            Text(
              normCurrent,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: RiceColors.textSecondary),
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
              final isSelected = preset.hex.toUpperCase() == normCurrent;
              final isTransparent = preset.hex == "#00000000";

              return Tooltip(
                message: preset.name,
                child: InkWell(
                  onTap: () => onPresetSelected(preset.hex),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isTransparent ? Colors.transparent : preset.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? RiceColors.laurelGold : RiceColors.borderLight,
                        width: isSelected ? 2.5 : 1.2,
                      ),
                    ),
                    child: isTransparent
                        ? const Center(child: Icon(Icons.block, size: 16, color: RiceColors.textSecondary))
                        : (isSelected
                            ? Center(
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: preset.color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                ),
                              )
                            : null),
                  ),
                ),
              );
            }),

            // Custom Picker Button
            Tooltip(
              message: "Custom Color Picker",
              child: InkWell(
                onTap: onCustomTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: RiceColors.borderLight, width: 1.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.colorize_rounded, size: 16, color: RiceColors.riceBlue),
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
