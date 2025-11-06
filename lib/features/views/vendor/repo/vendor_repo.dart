import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/vendor/models/vendor_model.dart';

class VendorRepo {
  Future<VendorModel> fetchVendors() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.getVendors,
      );

      return VendorModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
