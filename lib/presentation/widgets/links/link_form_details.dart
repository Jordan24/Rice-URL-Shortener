import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/rice_colors.dart';
import '../../../core/theme/rice_theme.dart';
import '../../../core/utils/code_generator.dart';
import '../../../core/utils/url_validator.dart';
import '../common/rice_text_field.dart';

class LinkFormDetails extends StatelessWidget {
  final TextEditingController destController;
  final TextEditingController? slugController;
  final bool isSlugEditable;
  final VoidCallback? onRegenerateSlug;
  final bool hasExpiration;
  final DateTime? expiresAt;
  final ValueChanged<bool> onToggleExpiration;
  final VoidCallback onPickExpirationDate;
  final TextEditingController fallbackController;

  const LinkFormDetails({
    super.key,
    required this.destController,
    this.slugController,
    this.isSlugEditable = true,
    this.onRegenerateSlug,
    required this.hasExpiration,
    required this.expiresAt,
    required this.onToggleExpiration,
    required this.onPickExpirationDate,
    required this.fallbackController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Link Details",
          style: RiceTheme.heading(fontSize: 18, fontWeight: FontWeight.w700, color: RiceColors.riceBlue),
        ),
        const SizedBox(height: 14),

        // Destination URL
        RiceTextField(
          label: "Destination Web Address *",
          hint: "e.g. rice.edu/admissions or drive.google.com/...",
          controller: destController,
          prefix: const Icon(Icons.link, size: 18, color: RiceColors.riceBlue),
          validator: (val) => UrlValidator.validateUrl(val, isRequired: true),
        ),

        if (slugController != null && isSlugEditable) ...[
          const SizedBox(height: 16),
          RiceTextField(
            label: "Custom Alias / Short Code *",
            hint: "5-char code or custom slug",
            controller: slugController,
            prefix: Padding(
              padding: const EdgeInsets.only(left: 12, right: 6, top: 14),
              child: Text(
                "rice.link/",
                style: RiceTheme.body(color: RiceColors.riceBlue, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            suffix: onRegenerateSlug != null
                ? Tooltip(
                    message: "Generate new random code",
                    child: IconButton(
                      icon: const Icon(Icons.autorenew_rounded, size: 18, color: RiceColors.riceBlue),
                      onPressed: onRegenerateSlug,
                    ),
                  )
                : null,
            validator: (val) => CodeGenerator.validateSlug(val),
          ),
        ],

        const SizedBox(height: 16),

        // Expiration Settings
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Set Expiration Date",
              style: RiceTheme.body(fontSize: 13, fontWeight: FontWeight.w600, color: RiceColors.textPrimary),
            ),
            Switch(
              value: hasExpiration,
              activeThumbColor: RiceColors.riceBlue,
              onChanged: onToggleExpiration,
            ),
          ],
        ),

        if (hasExpiration) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onPickExpirationDate,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: RiceColors.borderLight),
                borderRadius: BorderRadius.circular(6),
                color: RiceColors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: RiceColors.riceBlue),
                  const SizedBox(width: 10),
                  Text(
                    expiresAt != null
                        ? DateFormat("MMM d, yyyy at h:mm a").format(expiresAt!)
                        : "Select Date & Time",
                    style: RiceTheme.body(fontSize: 13, color: RiceColors.textPrimary),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, size: 14, color: RiceColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Fallback URL
          RiceTextField(
            label: "Fallback URL upon expiration",
            hint: "https://rice.edu",
            controller: fallbackController,
            helperText: "Redirects here automatically when link expires (default: rice.edu)",
            validator: (val) => UrlValidator.validateUrl(val, isRequired: false, fieldName: "Fallback URL"),
          ),
        ],
      ],
    );
  }
}
