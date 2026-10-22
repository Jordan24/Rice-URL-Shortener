import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/utils/url_validator.dart';
import '../../../data/models/qr_config.dart';
import '../../../data/services/qr_export_service.dart';
import '../common/rice_button.dart';
import '../common/rice_text_field.dart';
import '../links/link_form_qr_studio.dart';

class StandaloneQrModal extends StatefulWidget {
  const StandaloneQrModal({super.key});

  /// Derives a clean, filesystem-safe label from a target URL for downloaded files.
  static String deriveFileLabel(String url) {
    final uri = Uri.tryParse(url);
    final raw = (uri != null && uri.host.isNotEmpty) ? uri.host : 'custom';
    final sanitized = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (sanitized.isEmpty) return 'custom';
    return sanitized.length > 24 ? sanitized.substring(0, 24) : sanitized;
  }

  @override
  State<StandaloneQrModal> createState() => _StandaloneQrModalState();
}

class _StandaloneQrModalState extends State<StandaloneQrModal> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  QrConfig _qrConfig = const QrConfig();
  int _selectedSize = 512;
  bool _isDownloading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String get _previewUrl {
    final trimmed = _urlController.text.trim();
    if (trimmed.isEmpty) return AppConstants.defaultFallbackUrl;
    return UrlValidator.normalizeUrl(trimmed);
  }

  Future<void> _downloadPng() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isDownloading = true);
    try {
      final targetUrl = UrlValidator.normalizeUrl(_urlController.text);
      final label = StandaloneQrModal.deriveFileLabel(targetUrl);
      await QrExportService.exportPng(targetUrl, _qrConfig, label, _selectedSize);
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

  Future<void> _downloadSvg() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final targetUrl = UrlValidator.normalizeUrl(_urlController.text);
      final label = StandaloneQrModal.deriveFileLabel(targetUrl);
      await QrExportService.exportSvg(targetUrl, _qrConfig, label);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Downloaded scalable SVG successfully."),
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
    }
  }

  Widget _buildDetailsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "QR Code Destination",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: RiceColors.textPrimary),
        ),
        const SizedBox(height: 14),
        RiceTextField(
          label: "Destination Web Address *",
          hint: "e.g. rice.edu/admissions or drive.google.com/...",
          controller: _urlController,
          onChanged: (_) => setState(() {}),
          prefix: const Icon(Icons.link, size: 18, color: RiceColors.riceBlue),
          validator: (val) => UrlValidator.validateUrl(val, isRequired: true),
        ),
        const SizedBox(height: 20),
        const Text(
          "PNG Resolution",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RiceColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: RiceColors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RiceColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedSize,
              isExpanded: true,
              items: AppConstants.qrDownloadSizes.map((size) {
                String label = "$size x $size px";
                if (size <= 256) label += " (Small/Icon)";
                if (size == 512) label += " (Standard)";
                if (size >= 1024) label += " (High Res / Print)";
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSize = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: RiceColors.riceBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: RiceColors.riceBlue.withValues(alpha: 0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: RiceColors.riceBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "This QR code points directly to the web address above without creating a shortened link. It is not saved to your account—you will need to recreate it from scratch if you want to download it again later.",
                  style: TextStyle(fontSize: 12.5, color: RiceColors.textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Create Standalone QR Code",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: RiceColors.riceBlue),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final details = _buildDetailsColumn();
                        final qrStudio = LinkFormQrStudio(
                          previewUrl: _previewUrl,
                          qrConfig: _qrConfig,
                          onQrConfigChanged: (cfg) => setState(() => _qrConfig = cfg),
                        );

                        if (constraints.maxWidth > 650) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: details),
                              const SizedBox(width: 28),
                              Expanded(flex: 5, child: qrStudio),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            details,
                            const SizedBox(height: 24),
                            qrStudio,
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                    const SizedBox(width: 12),
                    RiceButton(
                      label: "Download SVG",
                      icon: Icons.polyline_rounded,
                      variant: RiceButtonVariant.outline,
                      onPressed: _downloadSvg,
                    ),
                    const SizedBox(width: 12),
                    RiceButton(
                      label: "Download PNG",
                      icon: Icons.download_rounded,
                      variant: RiceButtonVariant.primary,
                      isLoading: _isDownloading,
                      onPressed: _downloadPng,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
