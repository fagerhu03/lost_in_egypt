import 'dart:io';
import 'package:flutter/foundation.dart';

/// ✅ Image compression utility to optimize uploads
class ImageCompressionService {
  // ===== PARAMETERS =====
  static const int maxWidth = 1080;
  static const int maxHeight = 1080;
  static const int quality = 85; // 0-100, higher = better quality, larger file

  /// Compress a single image file
  /// Returns the compressed file, or original if compression fails
  static Future<File> compressImage(String imagePath) async {
    try {
      final originalFile = File(imagePath);
      final originalSize = await originalFile.length();

      debugPrint(
        '📸 Original image size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // For now, we'll just return the original file
      // In production, you'd use a package like:
      // - flutter_image_compress
      // - image_compression
      // - image (Dart library with native integration)

      // Example with flutter_image_compress (if added to pubspec.yaml):
      /*
      final compressed = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        imagePath.replaceAll('.jpg', '_compressed.jpg'),
        quality: quality,
        minHeight: maxHeight,
        minWidth: maxWidth,
        format: CompressFormat.jpeg,
      );
      
      if (compressed != null) {
        final compressedSize = await compressed.length();
        final reduction = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
        debugPrint('✅ Compressed: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB ($reduction% reduction)');
        return File(compressed.path);
      }
      */

      debugPrint(
        '⚠️ Image compression package not installed. Using original image.',
      );
      return originalFile;
    } catch (e) {
      debugPrint('❌ Error compressing image: $e');
      return File(imagePath);
    }
  }

  /// Compress multiple images
  static Future<List<File>> compressImages(List<File> images) async {
    final compressed = <File>[];

    for (final image in images) {
      try {
        final compressedFile = await compressImage(image.path);
        compressed.add(compressedFile);
      } catch (e) {
        debugPrint('⚠️ Failed to compress ${image.path}: $e');
        compressed.add(image);
      }
    }

    return compressed;
  }

  /// Get file size in MB
  static Future<double> getFileSizeMB(File file) async {
    final bytes = await file.length();
    return bytes / 1024 / 1024;
  }

  /// Get file size in KB
  static Future<double> getFileSizeKB(File file) async {
    final bytes = await file.length();
    return bytes / 1024;
  }

  /// Check if file is too large (e.g., > 10 MB)
  static Future<bool> isFileTooLarge(File file, {double maxSizeMB = 10}) async {
    final sizeMB = await getFileSizeMB(file);
    return sizeMB > maxSizeMB;
  }
}
