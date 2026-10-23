import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/theme/rice_theme.dart';
import '../../../core/utils/qr_contrast_helper.dart';

/// Shows an HSV color picker dialog for custom QR code foreground and background colors.
void showQrColorPickerDialog({
  required BuildContext context,
  required String currentHex,
  required ValueChanged<String> onSelected,
  required String title,
}) {
  Color pickerColor = QrContrastHelper.parseHexColor(currentHex);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        title,
        style: RiceTheme.heading(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: RiceColors.riceBlue,
        ),
      ),
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
          child: Text(
            "Cancel",
            style: RiceTheme.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: RiceColors.riceBlue,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final hex = "#${pickerColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}";
            onSelected(hex);
            Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: RiceColors.riceBlue,
            foregroundColor: Colors.white,
          ),
          child: Text(
            "Select",
            style: RiceTheme.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}
