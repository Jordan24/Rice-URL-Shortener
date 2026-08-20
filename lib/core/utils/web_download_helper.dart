import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Browser-native file download trigger for Flutter Web
class WebDownloadHelper {
  WebDownloadHelper._();

  /// Downloads raw byte data (e.g. PNG image) to the user device
  static void downloadBytes(Uint8List bytes, String filename, String mimeType) {
    final jsArray = [bytes.toJS].toJS;
    final blob = web.Blob(jsArray, web.BlobPropertyBag(type: mimeType));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  /// Downloads text data (e.g. SVG file) to the user device
  static void downloadString(String content, String filename, String mimeType) {
    final jsArray = [content.toJS].toJS;
    final blob = web.Blob(jsArray, web.BlobPropertyBag(type: mimeType));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}
