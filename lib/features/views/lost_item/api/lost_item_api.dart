import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/lost_item/enum/lost_reason_enum.dart';

class LostItemApi {
  static Future postLostItems({
    int? orderId,
    required XFile file,
    required int prodId,
    List<String> scannedTags = const [],
  }) async {
    try {
      // add in form data
      final formData = FormData.fromMap(
        {
          'image': await MultipartFile.fromFile(file.path, filename: file.name),
          'product_id': prodId,
          'reason': scannedTags.isNotEmpty
              ? LostReasonEnum.partialMissing.value
              : LostReasonEnum.notAvailable.value,
          'tags': scannedTags.toList(),
        },
      );

      //

      log(' ============ FormData: ${formData.fields} and  with values: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')} ============');

      final response = await DioClient().request(
        requestType: RequestType.postWithTokenFormData,
        url: AppUrls.lostItems(orderId),
        body: formData,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
