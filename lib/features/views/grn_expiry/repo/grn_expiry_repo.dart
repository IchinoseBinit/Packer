import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/grn_expiry/models/carton_intake_claim.dart';
import 'package:packer/utils/compress_file.dart';

class GrnExpiryRepo {
  /// Claims the carton for this staff. 400 used/expired/bad secret,
  /// 403 not warehouse staff, 404 not a carton QR — all thrown as AppException.
  static Future<CartonIntakeClaim> claim(String secret) async {
    final response = await DioClient().request(
      requestType: RequestType.postWithToken,
      url: AppUrls.cartonIntakeClaimUrl,
      body: {'qr': secret},
    );
    return CartonIntakeClaim.fromJson(response.data);
  }

  /// At least one of [mrpPhoto] / [expiryPhoto] must be given.
  static Future<void> uploadPhotos({
    required String grnItemId,
    required String sessionId,
    XFile? mrpPhoto,
    XFile? expiryPhoto,
  }) async {
    Future<MultipartFile> part(XFile f) async => MultipartFile.fromBytes(
          await FileHelper.compressToMaxSize(File(f.path)),
          filename: f.name,
        );
    await DioClient().request(
      requestType: RequestType.postWithTokenFormData,
      url: AppUrls.cartonIntakePhotosUrl(sessionId),
      body: FormData.fromMap({
        'session_id': sessionId,
        if (mrpPhoto != null) 'mrp_photo': await part(mrpPhoto),
        if (expiryPhoto != null) 'expiry_photo': await part(expiryPhoto),
      }),
    );
  }
}
