import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../data/models/short_link.dart';
import '../../../data/services/qr_export_service.dart';
import '../common/rice_button.dart';
import '../qr/qr_preview_card.dart';

class QrDownloadModal extends StatefulWidget {
  final ShortLink link;

  const QrDownloadModal({super.key, required this.link});

  @override
  State<QrDownloadModal> createState() => _QrDownloadModalState();
}

class _QrDownloadModalState extends State<QrDownloadModal> {
  int _selectedSize = 512;
  bool _isDownloading = false;

  Future<void> _downloadPng() async {
    setState(() => _isDownloading = true);
    try {
      final targetUrl = widget.link.fullShortUrl();
      await QrExportService.exportPng(targetUrl, widget.link.qrConfig, widget.link.shortCode, _selectedSize);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Downloaded PNG (${_selectedSize}x${_selectedSize}px) successfully."),
            backgroundColor: RiceColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Download failed: $e"), backgroundColor: RiceColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _downloadSvg() {
    try {
      final targetUrl = widget.link.fullShortUrl();
      QrExportService.exportSvg(targetUrl, widget.link.qrConfig, widget.link.shortCode);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Downloaded scalable SVG successfully."),
          backgroundColor: RiceColors.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e"), backgroundColor: RiceColors.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = widget.link.fullShortUrl();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Download QR Code",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RiceColors.riceBlue),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullUrl,
                        style: const TextStyle(fontSize: 12, color: RiceColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Preview
              QrPreviewCard(
                url: fullUrl,
                qrConfig: widget.link.qrConfig,
                size: 200,
              ),

              const SizedBox(height: 24),

              // Size selector for PNG (128, 256, 512, 1024, 2048)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "PNG Resolution:",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RiceColors.textPrimary),
                  ),
                  DropdownButton<int>(
                    value: _selectedSize,
                    underline: const SizedBox(),
                    items: AppConstants.qrDownloadSizes.map((size) {
                      String label = "$size x $size px";
                      if (size <= 256) label += " (Small/Icon)";
                      if (size == 512) label += " (Standard)";
                      if (size >= 1024) label += " (High Res / Print)";
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text(label, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSize = val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: RiceButton(
                      label: "Download SVG",
                      icon: Icons.polyline_rounded,
                      variant: RiceButtonVariant.outline,
                      onPressed: _downloadSvg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RiceButton(
                      label: "Download PNG",
                      icon: Icons.download_rounded,
                      variant: RiceButtonVariant.primary,
                      isLoading: _isDownloading,
                      onPressed: _downloadPng,
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
