import 'dart:developer';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/expiry_product/model/expiry_product_model.dart';

class ExpiredProductRepository {
  /// Fetch a single page of expired products
  Future<({Map<String, dynamic> data, List<Results> products})>
      fetchExpiredProductsPage({
    required int page,
    int? storeId,
  }) async {
    try {
      // Build paginated URL
      var url = "${AppUrls.expiryProductUrl}?page=$page";
      if (storeId != null && storeId != 0) {
        url += "&store_id=$storeId";
      }

      // Make API request
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(response.data);
      // Parse results safely
      final resultsData = (data['results'] as List?) ?? [];
      log("Fetched expired products: $resultsData");

      final newProducts = resultsData
          .map((item) => Results.fromJson(item))
          .whereType<Results>()
          .toList();

      return (data: data, products: newProducts);
    } catch (e, st) {
      log("Error fetching expired products page: $e\n$st");
      return (data: <String, dynamic>{}, products: <Results>[]);
    }
  }
}
