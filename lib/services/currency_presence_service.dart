import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

class CurrencyPresenceService {
  /// Check if the image contains a currency note using basic image analysis
  /// This is a simple heuristic-based approach that can be enhanced with actual ML models
  static Future<bool> hasCurrencyNote(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        return false;
      }

      // Perform multiple checks to determine if image likely contains currency
      final checks = [
        _checkImageSize(image),
        _checkBrightness(image),
        _checkColorVariety(image),
        _checkEdgeDetection(image),
        _checkAspectRatio(image),
      ];

      // At least 3 out of 5 checks should pass for currency detection
      final passedChecks = checks.where((check) => check).length;
      return passedChecks >= 3;
    } catch (e) {
      // If analysis fails, assume currency is present to avoid false negatives
      return true;
    }
  }

  /// Check if image has reasonable dimensions for currency
  static bool _checkImageSize(img.Image image) {
    const minWidth = 100;
    const minHeight = 50;
    const maxWidth = 5000;
    const maxHeight = 5000;

    return image.width >= minWidth &&
        image.width <= maxWidth &&
        image.height >= minHeight &&
        image.height <= maxHeight;
  }

  /// Check if image has reasonable brightness (not too dark or too bright)
  static bool _checkBrightness(img.Image image) {
    int totalBrightness = 0;
    int pixelCount = 0;

    // Sample every 10th pixel for performance
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;
        totalBrightness += brightness.toInt();
        pixelCount++;
      }
    }

    if (pixelCount == 0) return false;

    final avgBrightness = totalBrightness / pixelCount;

    // Currency notes typically have moderate brightness (not pure black/white)
    return avgBrightness > 30 && avgBrightness < 220;
  }

  /// Check if image has sufficient color variety (currency notes are colorful)
  static bool _checkColorVariety(img.Image image) {
    Set<int> uniqueColors = {};

    // Sample every 20th pixel for performance
    for (int y = 0; y < image.height; y += 20) {
      for (int x = 0; x < image.width; x += 20) {
        final pixel = image.getPixel(x, y);
        // Create a simplified color key
        final colorKey =
            ((pixel.r.toInt() ~/ 32) << 10) +
            ((pixel.g.toInt() ~/ 32) << 5) +
            (pixel.b.toInt() ~/ 32);
        uniqueColors.add(colorKey);

        // Stop if we have enough variety
        if (uniqueColors.length > 20) break;
      }
      if (uniqueColors.length > 20) break;
    }

    // Currency notes should have reasonable color variety
    return uniqueColors.length >= 8;
  }

  /// Simple edge detection to check for rectangular structures
  static bool _checkEdgeDetection(img.Image image) {
    try {
      // Simple Sobel edge detection on a subset of the image
      int edgeCount = 0;
      int totalChecked = 0;

      // Check central region of image (where currency likely is)
      final startX = image.width ~/ 4;
      final endX = (image.width * 3) ~/ 4;
      final startY = image.height ~/ 4;
      final endY = (image.height * 3) ~/ 4;

      for (int y = startY; y < endY - 1; y += 5) {
        for (int x = startX; x < endX - 1; x += 5) {
          if (x + 1 < image.width && y + 1 < image.height) {
            final currentPixel = image.getPixel(x, y);
            final rightPixel = image.getPixel(x + 1, y);
            final bottomPixel = image.getPixel(x, y + 1);

            final currentGray =
                (currentPixel.r + currentPixel.g + currentPixel.b) / 3;
            final rightGray = (rightPixel.r + rightPixel.g + rightPixel.b) / 3;
            final bottomGray =
                (bottomPixel.r + bottomPixel.g + bottomPixel.b) / 3;

            final gradientX = (rightGray - currentGray).abs();
            final gradientY = (bottomGray - currentGray).abs();
            final gradient = math.sqrt(
              gradientX * gradientX + gradientY * gradientY,
            );

            if (gradient > 30) {
              edgeCount++;
            }
            totalChecked++;
          }
        }
      }

      if (totalChecked == 0) return false;

      final edgeRatio = edgeCount / totalChecked;
      // Currency notes should have reasonable edge content
      return edgeRatio > 0.1 && edgeRatio < 0.8;
    } catch (e) {
      return true; // If edge detection fails, assume pass
    }
  }

  /// Check if image has reasonable aspect ratio for currency
  static bool _checkAspectRatio(img.Image image) {
    final aspectRatio = image.width / image.height;

    // Most currency notes have aspect ratios between 1.5:1 and 3:1
    // Also allow portrait orientation (inverse ratios)
    return (aspectRatio >= 1.5 && aspectRatio <= 3.0) ||
        (aspectRatio >= 0.33 && aspectRatio <= 0.67);
  }
}
