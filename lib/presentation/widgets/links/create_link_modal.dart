import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/utils/code_generator.dart';
import '../../../core/utils/url_validator.dart';
import '../../../data/models/qr_config.dart';
import '../../../data/models/short_link.dart';
import '../../state/auth_controller.dart';
import '../../state/link_controller.dart';
import '../common/rice_button.dart';
import 'link_form_details.dart';
import 'link_form_qr_studio.dart';

class CreateLinkModal extends StatefulWidget {
  final AuthController authController;
  final LinkController linkController;

  const CreateLinkModal({
    super.key,
    required this.authController,
    required this.linkController,
  });

  @override
  State<CreateLinkModal> createState() => _CreateLinkModalState();
}

class _CreateLinkModalState extends State<CreateLinkModal> {
  final _formKey = GlobalKey<FormState>();
  final _destController = TextEditingController();
  final _slugController = TextEditingController();
  final _fallbackController = TextEditingController(text: AppConstants.defaultFallbackUrl);

  DateTime? _expiresAt;
  bool _hasExpiration = false;
  QrConfig _qrConfig = const QrConfig();
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _slugController.text = CodeGenerator.generateShortCode();
  }

  void _regenerateShortCode() {
    setState(() {
      _slugController.text = CodeGenerator.generateShortCode();
    });
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: RiceColors.riceBlue,
            onPrimary: Colors.white,
            onSurface: RiceColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
      );

      setState(() {
        _expiresAt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime?.hour ?? 23,
          pickedTime?.minute ?? 59,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = widget.authController.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final destination = UrlValidator.normalizeUrl(_destController.text);
    final fallback = _fallbackController.text.trim().isNotEmpty
        ? UrlValidator.normalizeUrl(_fallbackController.text)
        : AppConstants.defaultFallbackUrl;
    final slug = CodeGenerator.sanitizeSlug(_slugController.text);

    final newLink = ShortLink(
      id: slug,
      userId: user.uid,
      userEmail: user.email,
      shortCode: slug,
      destinationUrl: destination,
      fallbackUrl: fallback,
      expiresAt: _hasExpiration ? _expiresAt : null,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      qrConfig: _qrConfig,
    );

    final success = await widget.linkController.createLink(newLink);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Short link https://${AppConstants.defaultDomain}/$slug created!"),
            backgroundColor: RiceColors.successGreen,
          ),
        );
      } else {
        setState(() {
          _isSaving = false;
          _error = widget.linkController.errorMessage ?? "Failed to create short link.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewSlug = _slugController.text.trim().isNotEmpty ? _slugController.text.trim() : 'xyz12';
    final previewUrl = 'https://${AppConstants.defaultDomain}/$previewSlug';

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
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Create Rice Short Link & QR Code",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: RiceColors.riceBlue),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),

                const Divider(height: 24),

                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: RiceColors.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: RiceColors.errorRed.withValues(alpha: 0.3)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: RiceColors.errorRed, fontSize: 13)),
                  ),
                ],

                Expanded(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isTwoColumn = constraints.maxWidth > 650;
                        final details = LinkFormDetails(
                          destController: _destController,
                          slugController: _slugController,
                          isSlugEditable: true,
                          onRegenerateSlug: _regenerateShortCode,
                          hasExpiration: _hasExpiration,
                          expiresAt: _expiresAt,
                          onToggleExpiration: (val) {
                            setState(() {
                              _hasExpiration = val;
                              if (val && _expiresAt == null) {
                                _expiresAt = DateTime.now().add(const Duration(days: 7));
                              }
                            });
                          },
                          onPickExpirationDate: _pickExpirationDate,
                          fallbackController: _fallbackController,
                        );

                        final qrStudio = LinkFormQrStudio(
                          previewUrl: previewUrl,
                          qrConfig: _qrConfig,
                          onQrConfigChanged: (cfg) => setState(() => _qrConfig = cfg),
                        );

                        if (isTwoColumn) {
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

                // Bottom Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 12),
                    RiceButton(
                      label: "Create Short Link",
                      icon: Icons.check,
                      isLoading: _isSaving,
                      onPressed: _submit,
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
