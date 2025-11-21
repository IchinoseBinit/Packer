import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/expiry_product/models/expired_product_details_model.dart';
import 'package:packer/features/views/expiry_product/models/expiry_product_model.dart';
import 'package:packer/utils/paginated_response.dart';

class ExpiredProductRepository {
  final DioClient _client = DioClient();

  Future<PaginatedResponse<Results>> fetchProductsPage(int page) async {
    try {
      final url = "${AppUrls.expiryProductUrl}?page=$page";

      final response = await _client.request(
        requestType: RequestType.getWithToken,
        url: url,
      );

      return PaginatedResponse<Results>.fromJson(
        response.data,
        (json) => Results.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ExpiredProductDetailsModel> fetchProductDetails(int id) async {
    try {
      final url = AppUrls.expiryProductDetailsUrl.replaceAll("id", "$id");

      final response = await _client.request(
        requestType: RequestType.getWithToken,
        url: url,
      );

      return ExpiredProductDetailsModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
