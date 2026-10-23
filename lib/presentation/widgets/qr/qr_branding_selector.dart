import 'package:flutter/material.dart';
import '../../../core/constants/branding_pack.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/constants/rice_logos.dart';
import '../../../core/theme/rice_theme.dart';

class QrBrandingSelector extends StatelessWidget {
  final BrandingPackType selectedPack;
  final ValueChanged<BrandingPackType> onBrandingPackChanged;

  const QrBrandingSelector({
    super.key,
    required this.selectedPack,
    required this.onBrandingPackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Branding Pack",
              style: RiceTheme.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RiceColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: RiceColors.riceBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                selectedPack == BrandingPackType.university ? "University" : "Residential College",
                style: RiceTheme.body(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: RiceColors.riceBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: RiceColors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RiceColors.borderLight, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BrandingPackType>(
              value: selectedPack,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: RiceColors.riceBlue),
              borderRadius: BorderRadius.circular(8),
              elevation: 4,
              onChanged: (pack) {
                if (pack != null && pack != selectedPack) {
                  onBrandingPackChanged(pack);
                }
              },
              items: BrandingPackType.values.map((pack) {
                final isSelected = pack == selectedPack;
                final assetPath = RiceLogos.getSelectorAssetPath(pack);

                return DropdownMenuItem<BrandingPackType>(
                  value: pack,
                  child: Row(
                    children: [
                      if (assetPath != null)
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            color: pack == BrandingPackType.university ? RiceColors.riceBlue : null,
                            colorBlendMode: pack == BrandingPackType.university ? BlendMode.srcIn : null,
                            filterQuality: FilterQuality.high,
                          ),
                        )
                      else
                        const SizedBox(width: 22, height: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pack.label,
                          style: RiceTheme.body(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? RiceColors.riceBlue : RiceColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
