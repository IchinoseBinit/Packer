import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/package_return/models/package_return_model.dart';

class PackageReturnApi {
  //
  static Future<PackageReturnModel> fetchPackageReturnData() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.packageReturnUrl,
      );
      return PackageReturnModel.fromJson(response.data);
    } catch (error) {
      rethrow;
    }
  }

  //
  static Future postPackageReturn(int id, List<String> packageIds) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.packageReturnDetailsUrl(id),
        body: {"identifiers": packageIds},
      );
      return response;
    } catch (error) {
      rethrow;
    }
  }
}
