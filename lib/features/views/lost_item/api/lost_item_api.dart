import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';

class LostItemApi {
  static Future postLostItems(
      {int? orderId, required Map<String, dynamic> items}) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.lostItems(orderId),
        body: items,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
