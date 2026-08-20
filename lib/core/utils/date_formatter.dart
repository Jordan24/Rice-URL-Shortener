import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('MMM d, yyyy h:mm a');
  static final DateFormat _shortDateFormat = DateFormat('MMM d, yyyy');

  /// Formats a DateTime for human-readable display
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return _displayFormat.format(dateTime.toLocal());
  }

  /// Formats just the date part
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return _shortDateFormat.format(dateTime.toLocal());
  }

  /// Returns a relative description e.g. "Expires in 2 days" or "Expired"
  static String formatRelativeExpiration(DateTime? expiresAt) {
    if (expiresAt == null) return 'No expiration';
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) {
      return 'Expired (${_shortDateFormat.format(expiresAt.toLocal())})';
    }

    final diff = expiresAt.difference(now);
    if (diff.inDays > 1) {
      return 'Expires in ${diff.inDays} days';
    } else if (diff.inHours > 1) {
      return 'Expires in ${diff.inHours} hours';
    } else if (diff.inMinutes > 0) {
      return 'Expires in ${diff.inMinutes} mins';
    } else {
      return 'Expires shortly';
    }
  }

  /// Determines if a link is currently expired
  static bool isExpired(DateTime? expiresAt) {
    if (expiresAt == null) return false;
    return expiresAt.isBefore(DateTime.now());
  }
}
