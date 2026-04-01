import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final projectRoot = Directory.current.path;
  final srcPath = '$projectRoot/assets/preparedapp.png';
  final outPath = '$projectRoot/assets/launcher_icon_final.png';

  final srcFile = File(srcPath);
  if (!srcFile.existsSync()) {
    print('ERROR: Could not find $srcPath');
    exit(1);
  }

  print('Loading source image: $srcPath');
  final srcBytes = srcFile.readAsBytesSync();
  final srcImage = decodeImage(srcBytes);
  if (srcImage == null) {
    print('ERROR: Failed to decode image.');
    exit(1);
  }

  const int size = 1024;

  // Create white background canvas
  final canvas = Image(width: size, height: size);
  fill(canvas, color: ColorRgb8(255, 255, 255));

  // Scale source image to cover the entire canvas (no letterboxing)
  final double scaleX = size / srcImage.width;
  final double scaleY = size / srcImage.height;
  final double scale = scaleX > scaleY ? scaleX : scaleY;

  final int newW = (srcImage.width * scale).round();
  final int newH = (srcImage.height * scale).round();

  final resized = copyResize(srcImage, width: newW, height: newH, interpolation: Interpolation.cubic);

  // Center-crop to 1024x1024
  final int offsetX = (newW - size) ~/ 2;
  final int offsetY = (newH - size) ~/ 2;
  final cropped = copyCrop(resized, x: offsetX, y: offsetY, width: size, height: size);

  // Composite onto white canvas
  compositeImage(canvas, cropped);

  // Save
  final outBytes = encodePng(canvas);
  File(outPath).writeAsBytesSync(outBytes);
  print('Saved processed launcher icon to: $outPath (${size}x${size})');
}
