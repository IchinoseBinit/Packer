import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/cleanliness/models/cleanliness_item.dart';
import 'package:packer/utils/compress_file.dart';

class CleanlinessRepo {
  static Future<CleanlinessReport> getReport() async {
    final response = await DioClient().request(
      requestType: RequestType.getWithToken,
      url: AppUrls.storeCleanlinessUrl,
    );
    log('===== store-cleanliness response: ${response.data} =====');
    return CleanlinessReport.fromJson(response.data);
  }

  /// Called when the 15s window runs out without a photo.
  static Future<void> markUnavailable(int itemId) async {
    await DioClient().request(
      requestType: RequestType.postWithToken,
      url: AppUrls.storeCleanlinessUnavailableUrl,
      body: {'item_id': itemId},
    );
  }

  static Future<void> uploadImage(int itemId, XFile file) async {
    final compressed =
        await FileHelper.compressToMaxSize(File(file.path), maxKb: 300);
    final formData = FormData.fromMap({
      'item_id': itemId,
      'image': MultipartFile.fromBytes(compressed, filename: file.name),
    });
    await DioClient().request(
      requestType: RequestType.postWithTokenFormData,
      url: AppUrls.storeCleanlinessUploadUrl,
      body: formData,
    );
  }
}
