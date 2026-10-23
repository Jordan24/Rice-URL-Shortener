import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/theme/rice_theme.dart';

class RiceFooter extends StatelessWidget {
  const RiceFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: RiceColors.darkBlue,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "© ${DateTime.now().year} Rice University • 6100 Main St., Houston, Texas 77005",
                style: RiceTheme.body(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  Text(
                    "Rice Brand Guidelines Compliant",
                    style: RiceTheme.body(
                      color: RiceColors.laurelGold.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
