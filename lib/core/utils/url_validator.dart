class UrlValidator {
  UrlValidator._();

  /// Normalizes a URL input by trimming and ensuring https:// if scheme is missing
  static String normalizeUrl(String input) {
    var trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;

    if (!trimmed.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }

  /// Validates if a string is a valid HTTP/HTTPS URL
  static String? validateUrl(String? input, {bool isRequired = true, String fieldName = 'Destination URL'}) {
    if (input == null || input.trim().isEmpty) {
      if (isRequired) {
        return '$fieldName is required.';
      }
      return null;
    }

    final normalized = normalizeUrl(input);
    final uri = Uri.tryParse(normalized);

    if (uri == null || !uri.hasScheme || !uri.hasAuthority || uri.host.isEmpty) {
      return 'Please enter a valid web address (e.g. rice.edu/event)';
    }

    // Basic domain structure check (must have at least one dot or be localhost)
    if (!uri.host.contains('.') && uri.host != 'localhost') {
      return 'Please enter a valid domain name.';
    }

    return null;
  }
}
