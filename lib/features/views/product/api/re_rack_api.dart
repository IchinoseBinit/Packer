import 'dart:developer';

import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/product/model/product_avaliability.dart';

class ReRackApi {
  //
  static Future<ProductAvailability?> postRerackProduct(int productId) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: '${AppUrls.productAvailabilityUrl}$productId/',
      );
      return ProductAvailability.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}
