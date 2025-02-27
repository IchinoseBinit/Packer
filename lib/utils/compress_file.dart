import 'dart:io';

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
}
