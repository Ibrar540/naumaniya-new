import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final projectRoot = Directory.current.path;

  final candidates = [
    '$projectRoot\\windows\\runner\\resources\\1.png',
    '$projectRoot\\windows\\runner\\resources\\png.png',
    '$projectRoot\\android\\app\\src\\main\\res\\mipmap-hdpi\\ic_launcher.png',
  ];

  String? src;
  for (final c in candidates) {
    if (await File(c).exists()) {
      src = c;
      break;
    }
  }

  if (src == null) {
    print('No source image found. Please place a PNG at windows\\runner\\resources\\1.png or mipmap-hdpi/ic_launcher.png');
    exit(1);
  }

  print('Using source image: $src');
  final srcBytes = await File(src).readAsBytes();
  final image = decodeImage(srcBytes);
  if (image == null) {
    print('Failed to decode source image. Ensure it is a valid PNG/JPG.');
    exit(1);
  }

  // Generate Android mipmap PNGs
  final mipmapSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in mipmapSizes.entries) {
    final dir = Directory('$projectRoot\\android\\app\\src\\main\\res\\${entry.key}');
    if (!await dir.exists()) continue;
    final outPath = '${dir.path}\\ic_launcher.png';
    final resized = copyResize(image, width: entry.value, height: entry.value, interpolation: Interpolation.cubic);
    // Backup existing
    final outFile = File(outPath);
    if (await outFile.exists()) {
      await outFile.copy('$outPath.bak');
    }
    await outFile.writeAsBytes(encodePng(resized));
    print('Wrote $outPath (${entry.value}x${entry.value})');
  }

  // Generate Windows ICO with a single PNG image embedded (256x256). This is widely supported.
  final icoSizes = [256];
  final png256 = copyResize(image, width: 256, height: 256, interpolation: Interpolation.cubic);
  final pngBytes = encodePng(png256);

  // Build ICO container with single image (ICONDIR + ICONDIRENTRY + PNG bytes)
  final List<int> ico = [];
  // ICONDIR: reserved(2 bytes), type(2 bytes), count(2 bytes)
  ico.addAll([0x00, 0x00]); // reserved
  ico.addAll([0x01, 0x00]); // type = 1 (icon)
  ico.addAll([0x01, 0x00]); // count = 1

  // ICONDIRENTRY (16 bytes)
  // width (1), height (1), colorCount (1), reserved (1), planes (2), bitCount (2), bytesInRes (4), imageOffset (4)
  final widthByte = 0x00; // 0 means 256
  final heightByte = 0x00; // 0 means 256
  ico.add(widthByte);
  ico.add(heightByte);
  ico.add(0x00); // colorCount
  ico.add(0x00); // reserved
  ico.addAll([0x01, 0x00]); // planes = 1
  ico.addAll([0x20, 0x00]); // bitCount = 32
  final bytesInRes = pngBytes.length;
  ico.addAll([bytesInRes & 0xFF, (bytesInRes >> 8) & 0xFF, (bytesInRes >> 16) & 0xFF, (bytesInRes >> 24) & 0xFF]);
  final imageOffset = 6 + 16; // ICONDIR(6) + ICONDIRENTRY(16)
  ico.addAll([imageOffset & 0xFF, (imageOffset >> 8) & 0xFF, (imageOffset >> 16) & 0xFF, (imageOffset >> 24) & 0xFF]);

  // Append PNG bytes
  ico.addAll(pngBytes);

  final icoPath = '$projectRoot\\windows\\runner\\resources\\app_icon.ico';
  final icoFile = File(icoPath);
  if (await icoFile.exists()) await icoFile.copy('$icoPath.bak');
  await icoFile.writeAsBytes(ico);
  print('Wrote $icoPath (ICO embedding 256x256 PNG)');

  print('Icon generation complete.');
}
