import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/rice_colors.dart';
import '../state/auth_controller.dart';
import '../widgets/common/rice_button.dart';
import '../widgets/common/rice_card.dart';
import '../widgets/common/rice_footer.dart';

class AuthView extends StatelessWidget {
  final AuthController authController;

  const AuthView({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiceColors.surfaceBackground,
      body: Column(
        children: [
          // Rice Blue institutional banner
          Container(
            width: double.infinity,
            color: RiceColors.riceBlue,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, color: RiceColors.laurelGold, size: 32),
                    const SizedBox(width: 14),
                    Text(
                      "RICE UNIVERSITY",
                      style: GoogleFonts.cormorantGaramond(
                        color: RiceColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Login Content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: RiceCard(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon & Title
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: RiceColors.riceBlue.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.link_rounded, size: 36, color: RiceColors.riceBlue),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          "URL Shortener & QR Studio",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: RiceColors.riceBlue,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          "Create official custom short links, custom aliases, and styled QR codes for Rice University.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(fontSize: 14, color: RiceColors.textSecondary, height: 1.4),
                        ),

                        const SizedBox(height: 28),

                        if (authController.errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: RiceColors.errorRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: RiceColors.errorRed.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: RiceColors.errorRed, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authController.errorMessage!,
                                    style: const TextStyle(color: RiceColors.errorRed, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Sign in button
                        RiceButton(
                          label: "Sign in with Rice Account",
                          icon: Icons.login_rounded,
                          variant: RiceButtonVariant.primary,
                          isLoading: authController.isLoading,
                          width: double.infinity,
                          onPressed: () => authController.signInWithGoogle(),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 18, color: RiceColors.riceBlue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Restricted to verified @rice.edu email accounts.",
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: RiceColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
