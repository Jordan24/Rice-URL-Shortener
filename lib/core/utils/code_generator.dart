import 'dart:math';
import '../constants/app_constants.dart';

class CodeGenerator {
  CodeGenerator._();

  static const String _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  static final Random _random = Random.secure();

  /// Generates a random 5-character alphanumeric short code
  static String generateShortCode([int length = AppConstants.defaultCodeLength]) {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_alphabet[_random.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }

  /// Sanitizes a custom alias / slug to lower-case url-safe format
  static String sanitizeSlug(String slug) {
    return slug.trim().toLowerCase();
  }

  /// Validates whether a custom slug is valid and not reserved
  static String? validateSlug(String? slug) {
    if (slug == null || slug.trim().isEmpty) {
      return 'Short code or custom alias is required.';
    }

    final sanitized = sanitizeSlug(slug);

    if (sanitized.length < 3 || sanitized.length > 30) {
      return 'Alias must be between 3 and 30 characters.';
    }

    final regex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!regex.hasMatch(sanitized)) {
      return 'Alias can only contain letters, numbers, hyphens, and underscores.';
    }

    if (AppConstants.reservedRoutes.contains(sanitized)) {
      return '"$sanitized" is a reserved system path and cannot be used.';
    }

    return null;
  }
}
