import 'dart:developer';

import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';

class LowStockRepo {
  static Future<List<LowStockModel>> getLowStock() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.lowStockForWareHouseUrl,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((item) => LowStockModel.fromJson(item))
            .toList();
      } else {
        throw Exception("Unable to parse response");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<ProductModel>> getProduct(
      {required int storeId, int? vendorId}) async {
    try {
      final url =
          AppUrls.productByStoreAndVendor.replaceAll("SID", storeId.toString());

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: vendorId != null ? "$url?vendor_id=$vendorId" : url,
      );

      if (response.data['products'] is List) {
        final data = (response.data['products'] as List)
            .map((item) => ProductModel.fromJson(item))
            .toList();

        return data;
      } else {
        throw Exception("Unable to parse response");
      }
    } catch (e) {
      rethrow;
    }
  }
}
