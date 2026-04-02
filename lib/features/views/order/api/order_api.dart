import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';

class OrderApi {
  //
  static Future<bool> checkPackage(String tag) async {
    try {
      await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.checkPackageUrl + tag,
      );
      return true;
    } catch (error) {
      rethrow;
    }
  }
}
