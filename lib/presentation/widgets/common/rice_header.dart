import 'package:flutter/material.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/theme/rice_theme.dart';
import '../../state/auth_controller.dart';

class RiceHeader extends StatelessWidget implements PreferredSizeWidget {
  final AuthController authController;
  final VoidCallback? onCreateLinkPressed;
  final VoidCallback? onCreateQrPressed;

  const RiceHeader({
    super.key,
    required this.authController,
    this.onCreateLinkPressed,
    this.onCreateQrPressed,
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
                    style: RiceTheme.heading(
                      color: RiceColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "URL Shortener & QR Studio",
                    style: RiceTheme.body(
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
            if (onCreateQrPressed != null) ...[
              OutlinedButton.icon(
                onPressed: onCreateQrPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: RiceColors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.qr_code_2_rounded, size: 19, color: RiceColors.laurelGold),
                label: Text(
                  "Create QR Code",
                  style: RiceTheme.body(fontWeight: FontWeight.w600, color: RiceColors.white),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (onCreateLinkPressed != null)
              ElevatedButton.icon(
                onPressed: onCreateLinkPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiceColors.laurelGold,
                  foregroundColor: RiceColors.darkBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.link_rounded, size: 20),
                label: Text(
                  "Create Short Link",
                  style: RiceTheme.body(fontWeight: FontWeight.w700, color: RiceColors.darkBlue),
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
                        style: RiceTheme.body(fontWeight: FontWeight.w700, color: RiceColors.textPrimary),
                      ),
                      Text(
                        user?.email ?? "",
                        style: RiceTheme.body(fontSize: 12, color: RiceColors.textSecondary),
                      ),
                      const Divider(height: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: "signout",
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 18, color: RiceColors.errorRed),
                      const SizedBox(width: 8),
                      Text("Sign Out", style: RiceTheme.body(color: RiceColors.errorRed, fontWeight: FontWeight.w600)),
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
                        style: RiceTheme.body(color: RiceColors.riceBlue, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        user?.displayName ?? "Rice User",
                        overflow: TextOverflow.ellipsis,
                        style: RiceTheme.body(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
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
