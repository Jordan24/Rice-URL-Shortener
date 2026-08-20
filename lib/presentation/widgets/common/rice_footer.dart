import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/rice_colors.dart';

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
                style: GoogleFonts.lato(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  Text(
                    "Rice Brand Guidelines Compliant",
                    style: GoogleFonts.lato(
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
