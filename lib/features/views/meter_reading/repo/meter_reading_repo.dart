import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/utils/compress_file.dart';

class MeterReadingRepo {
  /// Sends one electricity meter reading — the units read off the meter plus
  /// the photo of it.
  static Future<void> submit({
    required String readingUnits,
    required XFile image,
  }) async {
    final compressed =
        await FileHelper.compressToMaxSize(File(image.path), maxKb: 300);
    await DioClient().request(
      requestType: RequestType.postWithTokenFormData,
      url: AppUrls.meterReadingUrl,
      body: FormData.fromMap({
        'reading_units': readingUnits,
        'reading_image':
            MultipartFile.fromBytes(compressed, filename: image.name),
      }),
    );
  }
}
