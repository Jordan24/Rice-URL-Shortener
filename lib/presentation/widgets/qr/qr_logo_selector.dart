import 'package:flutter/material.dart';
import '../../../core/constants/branding_pack.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/constants/rice_logos.dart';
import '../../../core/theme/rice_theme.dart';

class QrLogoSelector extends StatelessWidget {
  final RiceLogoType selectedLogo;
  final BrandingPackType brandingPack;
  final ValueChanged<RiceLogoType> onLogoChanged;

  const QrLogoSelector({
    super.key,
    required this.selectedLogo,
    this.brandingPack = BrandingPackType.university,
    required this.onLogoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final logos = RiceLogos.getLogosForPack(brandingPack);
    final sectionTitle = brandingPack == BrandingPackType.university
        ? "Center Rice University Logo"
        : "Center ${brandingPack.shortName} Crest / Logo";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: RiceTheme.body(fontSize: 13, fontWeight: FontWeight.w600, color: RiceColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Column(
          children: logos.map((logo) {
            final isSelected = logo == selectedLogo;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => onLogoChanged(logo),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? RiceColors.riceBlue.withValues(alpha: 0.06) : RiceColors.white,
                    border: Border.all(
                      color: isSelected ? RiceColors.riceBlue : RiceColors.borderLight,
                      width: isSelected ? 1.6 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      if (logo == RiceLogoType.none)
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: RiceColors.lightGray,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: RiceColors.borderLight),
                          ),
                          child: const Center(
                            child: Icon(Icons.block_rounded, size: 16, color: RiceColors.textSecondary),
                          ),
                        )
                      else
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? RiceColors.riceBlue : RiceColors.borderLight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.asset(
                              RiceLogos.getAssetPath(logo)!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              logo.label,
                              style: RiceTheme.body(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? RiceColors.riceBlue : RiceColors.textPrimary,
                              ),
                            ),
                            Text(
                              logo.description,
                              style: RiceTheme.body(fontSize: 11, color: RiceColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      // ignore: deprecated_member_use
                      Radio<RiceLogoType>(
                        value: logo,
                        // ignore: deprecated_member_use
                        groupValue: selectedLogo,
                        activeColor: RiceColors.riceBlue,
                        // ignore: deprecated_member_use
                        onChanged: (val) {
                          if (val != null) onLogoChanged(val);
                        },
                      ),
                    ],
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
