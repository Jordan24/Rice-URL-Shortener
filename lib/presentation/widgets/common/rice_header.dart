import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/rice_colors.dart';
import '../../state/auth_controller.dart';

class RiceHeader extends StatelessWidget implements PreferredSizeWidget {
  final AuthController authController;
  final VoidCallback? onCreateLinkPressed;

  const RiceHeader({
    super.key,
    required this.authController,
    this.onCreateLinkPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser;

    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: RiceColors.riceBlue,
        border: Border(bottom: BorderSide(color: RiceColors.laurelGold, width: 3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Rice University Brand Wordmark
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.link_rounded, color: RiceColors.laurelGold, size: 26),
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RICE UNIVERSITY",
                    style: GoogleFonts.cormorantGaramond(
                      color: RiceColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "URL Shortener & QR Studio",
                    style: GoogleFonts.lato(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Actions
          if (authController.isAuthenticated) ...[
            if (onCreateLinkPressed != null)
              ElevatedButton.icon(
                onPressed: onCreateLinkPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiceColors.laurelGold,
                  foregroundColor: RiceColors.darkBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  "Create Short Link",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(width: 16),

            // User Profile Menu
            PopupMenuButton<String>(
              offset: const Offset(0, 48),
              onSelected: (val) {
                if (val == "signout") {
                  authController.signOut();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? "Rice User",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: RiceColors.textPrimary),
                      ),
                      Text(
                        user?.email ?? "",
                        style: const TextStyle(fontSize: 12, color: RiceColors.textSecondary),
                      ),
                      const Divider(height: 16),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "signout",
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: RiceColors.errorRed),
                      SizedBox(width: 8),
                      Text("Sign Out", style: TextStyle(color: RiceColors.errorRed)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: RiceColors.laurelGold,
                      child: Text(
                        (user?.displayName ?? "U").substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: RiceColors.riceBlue, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        user?.displayName ?? "Rice User",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
