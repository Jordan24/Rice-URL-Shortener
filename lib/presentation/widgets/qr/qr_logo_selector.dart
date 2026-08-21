import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/constants/rice_logos.dart';

class QrLogoSelector extends StatelessWidget {
  final RiceLogoType selectedLogo;
  final ValueChanged<RiceLogoType> onLogoChanged;

  const QrLogoSelector({
    super.key,
    required this.selectedLogo,
    required this.onLogoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Center Rice University Logo",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RiceColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Column(
          children: RiceLogoType.values.map((logo) {
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
                            color: Colors.grey.shade100,
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
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? RiceColors.riceBlue : RiceColors.textPrimary,
                              ),
                            ),
                            Text(
                              logo.description,
                              style: const TextStyle(fontSize: 11, color: RiceColors.textSecondary),
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
