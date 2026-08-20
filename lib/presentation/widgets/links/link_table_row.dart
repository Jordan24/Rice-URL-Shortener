import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/short_link.dart';
import '../common/rice_card.dart';

class LinkTableRow extends StatelessWidget {
  final ShortLink link;
  final VoidCallback onToggleActive;
  final VoidCallback onQrPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const LinkTableRow({
    super.key,
    required this.link,
    required this.onToggleActive,
    required this.onQrPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  void _copyToClipboard(BuildContext context) {
    final url = link.fullShortUrl();
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied $url to clipboard!"),
        backgroundColor: RiceColors.riceBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortUrl = link.fullShortUrl();
    final isExpired = link.isExpired;
    final isEffectivelyActive = link.isEffectivelyActive;

    return RiceCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        shortUrl,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: RiceColors.riceBlue,
                        ),
                      ),
                    ),
                    _buildStatusBadge(isExpired, isEffectivelyActive),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  link.destinationUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: RiceColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildClickBadge(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormatter.formatRelativeExpiration(link.expiresAt),
                        style: const TextStyle(fontSize: 12, color: RiceColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text("Active", style: TextStyle(fontSize: 12)),
                        Switch(
                          value: link.isActive,
                          activeThumbColor: RiceColors.riceBlue,
                          onChanged: (_) => onToggleActive(),
                        ),
                      ],
                    ),
                    _buildActionButtons(context),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              // Shortcode & Destination
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SelectableText(
                          shortUrl,
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: RiceColors.riceBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(isExpired, isEffectivelyActive),
                        const SizedBox(width: 8),
                        _buildClickBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link.destinationUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: RiceColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Expiration
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.formatRelativeExpiration(link.expiresAt),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isExpired ? RiceColors.errorRed : RiceColors.textPrimary,
                      ),
                    ),
                    if (link.fallbackUrl.isNotEmpty && link.fallbackUrl != "https://rice.edu")
                      Text(
                        "Fallback: ${link.fallbackUrl}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: RiceColors.textSecondary),
                      ),
                  ],
                ),
              ),

              // Active Switch
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Tooltip(
                  message: link.isActive ? "Link is Active" : "Link is Disabled",
                  child: Switch(
                    value: link.isActive,
                    activeThumbColor: RiceColors.riceBlue,
                    onChanged: (_) => onToggleActive(),
                  ),
                ),
              ),

              // Action Buttons
              _buildActionButtons(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClickBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: RiceColors.riceBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_outlined, size: 12, color: RiceColors.riceBlue),
          const SizedBox(width: 3),
          Text(
            "${link.clickCount} ${link.clickCount == 1 ? 'click' : 'clicks'}",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: RiceColors.riceBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isExpired, bool isEffectivelyActive) {
    Color bg;
    Color fg;
    String label;

    if (isExpired) {
      bg = RiceColors.errorRed.withValues(alpha: 0.12);
      fg = RiceColors.errorRed;
      label = "Expired";
    } else if (isEffectivelyActive) {
      bg = RiceColors.successGreen.withValues(alpha: 0.12);
      fg = RiceColors.successGreen;
      label = "Active";
    } else {
      bg = RiceColors.riceGray.withValues(alpha: 0.12);
      fg = RiceColors.riceGray;
      label = "Inactive";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: "Copy Link",
          child: IconButton(
            onPressed: () => _copyToClipboard(context),
            icon: const Icon(Icons.copy_rounded, size: 18, color: RiceColors.riceBlue),
          ),
        ),
        Tooltip(
          message: "QR Code Studio",
          child: IconButton(
            onPressed: onQrPressed,
            icon: const Icon(Icons.qr_code_2_rounded, size: 20, color: RiceColors.riceBlue),
          ),
        ),
        Tooltip(
          message: "Edit Link",
          child: IconButton(
            onPressed: onEditPressed,
            icon: const Icon(Icons.edit_outlined, size: 18, color: RiceColors.textSecondary),
          ),
        ),
        Tooltip(
          message: "Delete Link",
          child: IconButton(
            onPressed: onDeletePressed,
            icon: const Icon(Icons.delete_outline, size: 18, color: RiceColors.errorRed),
          ),
        ),
      ],
    );
  }
}
