import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/rice_colors.dart';
import '../../data/models/short_link.dart';
import '../state/auth_controller.dart';
import '../state/link_controller.dart';
import '../widgets/common/rice_button.dart';
import '../widgets/common/rice_card.dart';
import '../widgets/common/rice_footer.dart';
import '../widgets/common/rice_header.dart';
import '../widgets/links/create_link_modal.dart';
import '../widgets/links/edit_link_modal.dart';
import '../widgets/links/link_search_bar.dart';
import '../widgets/links/link_table_row.dart';
import '../widgets/links/qr_download_modal.dart';

class DashboardView extends StatefulWidget {
  final AuthController authController;
  final LinkController linkController;

  const DashboardView({
    super.key,
    required this.authController,
    required this.linkController,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    final user = widget.authController.currentUser;
    if (user != null) {
      widget.linkController.init(user.uid);
    }
  }

  void _openCreateModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateLinkModal(
        authController: widget.authController,
        linkController: widget.linkController,
      ),
    );
  }

  void _openEditModal(ShortLink link) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditLinkModal(
        link: link,
        linkController: widget.linkController,
      ),
    );
  }

  void _openQrModal(ShortLink link) {
    showDialog(
      context: context,
      builder: (ctx) => QrDownloadModal(link: link),
    );
  }

  void _confirmDelete(ShortLink link) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Short Link?"),
        content: Text('Are you sure you want to permanently delete "${link.shortCode}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              widget.linkController.deleteLink(link.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link deleted."), backgroundColor: RiceColors.riceBlue),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: RiceColors.errorRed, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final links = widget.linkController.filteredLinks;
    final allLinks = widget.linkController.allLinks;
    final activeCount = allLinks.where((l) => l.isEffectivelyActive).length;
    final expiredCount = allLinks.where((l) => l.isExpired).length;

    return Scaffold(
      backgroundColor: RiceColors.surfaceBackground,
      appBar: RiceHeader(
        authController: widget.authController,
        onCreateLinkPressed: _openCreateModal,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header title & quick action for mobile
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Rice Link & QR Studio",
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: RiceColors.riceBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Manage all your university custom URLs and download Rice-branded QR codes.",
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: RiceColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Stats Row
                      Row(
                        children: [
                          _buildStatCard("Total Links", allLinks.length.toString(), Icons.link_rounded, RiceColors.riceBlue),
                          const SizedBox(width: 16),
                          _buildStatCard("Active Links", activeCount.toString(), Icons.check_circle_outline, RiceColors.successGreen),
                          const SizedBox(width: 16),
                          _buildStatCard("Expired Links", expiredCount.toString(), Icons.timer_off_outlined, RiceColors.errorRed),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Search and Filter Bar
                      LinkSearchBar(
                        searchQuery: widget.linkController.searchQuery,
                        statusFilter: widget.linkController.statusFilter,
                        onSearchChanged: widget.linkController.setSearchQuery,
                        onStatusChanged: widget.linkController.setStatusFilter,
                      ),

                      const SizedBox(height: 20),

                      // Links List / Empty State
                      if (widget.linkController.isLoading && allLinks.isEmpty) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: CircularProgressIndicator(color: RiceColors.riceBlue),
                          ),
                        ),
                      ] else if (links.isEmpty) ...[
                        _buildEmptyState(),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: links.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final link = links[i];
                            return LinkTableRow(
                              link: link,
                              onToggleActive: () => widget.linkController.toggleActive(link),
                              onQrPressed: () => _openQrModal(link),
                              onEditPressed: () => _openEditModal(link),
                              onDeletePressed: () => _confirmDelete(link),
                            );
                          },
                        ),
                      ],
                    ],
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

  Widget _buildStatCard(String title, String count, IconData icon, Color accentColor) {
    return Expanded(
      child: RiceCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.w800, color: RiceColors.textPrimary),
                ),
                Text(
                  title,
                  style: GoogleFonts.lato(fontSize: 12, color: RiceColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: RiceCard(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RiceColors.riceBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 48, color: RiceColors.riceBlue),
            ),
            const SizedBox(height: 20),
            Text(
              "No Short Links Found",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: RiceColors.riceBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Create your first Rice University shortened link and styled QR code.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 14, color: RiceColors.textSecondary),
            ),
            const SizedBox(height: 24),
            RiceButton(
              label: "Create Short Link",
              icon: Icons.add_rounded,
              variant: RiceButtonVariant.primary,
              onPressed: _openCreateModal,
            ),
          ],
        ),
      ),
    );
  }
}
