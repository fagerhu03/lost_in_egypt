import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageUtils {
  /// Compresses a local image file.
  /// 
  /// Reduces the quality to 70 and scales down the image to a max width/height of 1080px
  /// to ensure fast upload times, low Firebase Storage usage, and quick download
  /// times for users on the other end, resolving high-quality image load issues.
  static Future<File?> compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = tempDir.path;
      final uuid = const Uuid().v4();
      final targetPath = '$path/compressed_$uuid.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // 70% quality
        minWidth: 1080, // Scale down super-large images
        minHeight: 1080,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      // If compression fails for any reason, return the original file
      // to avoid breaking the upload flow.
      return file;
    }
  }
}
