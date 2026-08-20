import 'dart:typed_data';

/// Fallback / Stub file download helper for non-web environments (such as unit tests on Dart VM)
class WebDownloadHelper {
  WebDownloadHelper._();

  /// Downloads raw byte data (e.g. PNG image) to the user device (no-op in test/VM)
  static void downloadBytes(Uint8List bytes, String filename, String mimeType) {}

  /// Downloads text data (e.g. SVG file) to the user device (no-op in test/VM)
  static void downloadString(String content, String filename, String mimeType) {}
}
