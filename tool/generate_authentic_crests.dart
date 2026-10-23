// ignore_for_file: avoid_print
import 'dart:collection';
import 'dart:io';
import 'package:image/image.dart' as img;

img.Image removeOutsideWhiteBackground(img.Image src, {int threshold = 230}) {
  if (src.numChannels != 4) {
    src = src.convert(numChannels: 4);
  }
  final width = src.width;
  final height = src.height;
  final visited = List<bool>.filled(width * height, false);
  final queue = Queue<int>();

  bool isWhite(int x, int y) {
    final p = src.getPixel(x, y);
    return p.r >= threshold && p.g >= threshold && p.b >= threshold;
  }

  void enqueue(int x, int y) {
    final idx = y * width + x;
    if (!visited[idx] && isWhite(x, y)) {
      visited[idx] = true;
      queue.add(idx);
    }
  }

  // Enqueue 4 edges
  for (int x = 0; x < width; x++) {
    enqueue(x, 0);
    enqueue(x, height - 1);
  }
  for (int y = 0; y < height; y++) {
    enqueue(0, y);
    enqueue(width - 1, y);
  }

  // BFS flood fill from edges to make background transparent
  while (queue.isNotEmpty) {
    final idx = queue.removeFirst();
    final x = idx % width;
    final y = idx ~/ width;

    final p = src.getPixel(x, y);
    p.a = 0;

    if (x > 0) enqueue(x - 1, y);
    if (x < width - 1) enqueue(x + 1, y);
    if (y > 0) enqueue(x, y - 1);
    if (y < height - 1) enqueue(x, y + 1);
  }

  return src;
}

img.Image processCrest(String sourcePath, {bool floodFillWhite = false}) {
  final file = File(sourcePath);
  if (!file.existsSync()) {
    throw Exception('Source file does not exist: $sourcePath');
  }
  final bytes = file.readAsBytesSync();
  var image = img.decodeImage(bytes)!;
  if (image.numChannels != 4) {
    image = image.convert(numChannels: 4);
  }

  if (floodFillWhite) {
    image = removeOutsideWhiteBackground(image, threshold: 230);
  }

  // Find bounding box of non-transparent pixels
  int minX = image.width, maxX = 0, minY = image.height, maxY = 0;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a > 10) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  img.Image cropped;
  if (minX <= maxX && minY <= maxY) {
    cropped = img.copyCrop(
      image,
      x: minX,
      y: minY,
      width: (maxX - minX + 1),
      height: (maxY - minY + 1),
    );
  } else {
    cropped = image;
  }

  // Scale to fit within 460x460 to preserve padding
  final double scale = 460.0 / (cropped.width > cropped.height ? cropped.width : cropped.height);
  final int targetW = (cropped.width * scale).round();
  final int targetH = (cropped.height * scale).round();
  final resized = img.copyResize(
    cropped,
    width: targetW,
    height: targetH,
    interpolation: img.Interpolation.linear,
  );

  // Composite onto 512x512 transparent canvas
  final canvas = img.Image(width: 512, height: 512, numChannels: 4);
  final dstX = (512 - resized.width) ~/ 2;
  final dstY = (512 - resized.height) ~/ 2;
  img.compositeImage(canvas, resized, dstX: dstX, dstY: dstY);

  return canvas;
}

void main() {
  final Map<String, ({String path, bool floodFill})> sources = {
    'college_baker.png': (path: '/tmp/bakerCrest.png', floodFill: false),
    'college_will_rice.png': (path: '/tmp/willrice.png', floodFill: false),
    'college_hanszen.png': (path: '/tmp/hanszen.png', floodFill: false),
    'college_wiess.png': (path: '/tmp/rice_studentlife/wiess.jpg', floodFill: true),
    'college_jones.png': (path: '/tmp/jones_logo.jpeg', floodFill: true),
    'college_brown.png': (path: '/tmp/rice_studentlife/brown.jpg', floodFill: true),
    'college_lovett.png': (path: '/tmp/rice_studentlife/lovett.jpg', floodFill: true),
    'college_sid_richardson.png': (path: '/tmp/rice_studentlife/sid_richardson.jpg', floodFill: true),
    'college_martel.png': (path: '/tmp/martel.png', floodFill: false),
    'college_mcmurtry.png': (path: '/tmp/mcmurtry.png', floodFill: false),
    'college_duncan.png': (path: '/tmp/duncan.png', floodFill: false),
    'college_chao.png': (path: '/tmp/rice_studentlife/chao.png', floodFill: false),
  };

  for (final entry in sources.entries) {
    final destPath = 'assets/logos/${entry.key}';
    final processed = processCrest(entry.value.path, floodFillWhite: entry.value.floodFill);
    final pngBytes = img.encodePng(processed);
    File(destPath).writeAsBytesSync(pngBytes);

    final decoded = img.decodePng(pngBytes)!;
    assert(decoded.width == 512 && decoded.height == 512);
    for (final pt in [(0, 0), (511, 0), (0, 511), (511, 511), (256, 5), (5, 256), (506, 256), (256, 506)]) {
      assert(decoded.getPixel(pt.$1, pt.$2).a == 0, 'Pixel at $pt must be transparent for ${entry.key}');
    }
    print('Generated: $destPath (${pngBytes.length} bytes, 512x512 transparent)');
  }
}
