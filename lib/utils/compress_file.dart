import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileHelper {
  compressFile(File imageFile) async {
    // Check the file size
    int fileSize = await imageFile.length();
    const int oneMbInBytes = 1024 * 1024;

    // Get the file extension by splitting the path
    List<String> splitPath = imageFile.path.split('.');
    String fileExtension = splitPath.last;

    // Compress if file size is greater than 1 MB
    if (fileSize > oneMbInBytes) {
      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        '${imageFile.path.split('.').first}_compressed.$fileExtension',
        quality:
            50, // Adjust quality as needed, lower value for more compression
      );

      if (compressedImage != null) {
        return compressedImage;
      }
      return imageFile;
    } else {
      return imageFile;
    }
  }

  /// Compresses [imageFile] to at most [maxKb], stepping quality down until
  /// it fits (or quality bottoms out — returns the smallest it could reach).
  static Future<Uint8List> compressToMaxSize(
    File imageFile, {
    int maxKb = 300,
  }) async {
    final maxBytes = maxKb * 1024;
    var bytes = await imageFile.readAsBytes();
    if (bytes.lengthInBytes <= maxBytes) return bytes;

    for (var quality = 80; quality >= 10; quality -= 10) {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
      );
      bytes = compressed;
      if (bytes.lengthInBytes <= maxBytes) break;
    }
    return bytes;
  }
}
