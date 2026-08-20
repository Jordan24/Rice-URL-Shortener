import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/rice_colors.dart';
import '../widgets/common/rice_button.dart';
import '../widgets/common/rice_card.dart';
import '../widgets/common/rice_footer.dart';

class NotFoundView extends StatelessWidget {
  final String? code;

  const NotFoundView({super.key, this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiceColors.surfaceBackground,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: RiceColors.riceBlue,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: RiceColors.laurelGold, size: 28),
                const SizedBox(width: 12),
                Text(
                  "RICE UNIVERSITY",
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // 404 Body
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: RiceCard(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "404",
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            color: RiceColors.riceBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Link Not Found or Expired",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: RiceColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          code != null
                              ? 'The short link "$code" does not exist or has been disabled.'
                              : "The requested short link could not be found.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(fontSize: 14, color: RiceColors.textSecondary),
                        ),
                        const SizedBox(height: 28),
                        RiceButton(
                          label: "Return to Rice Homepage",
                          icon: Icons.home_rounded,
                          variant: RiceButtonVariant.primary,
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, "/");
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const RiceFooter(),
        ],
      ),
    );
  }
}
