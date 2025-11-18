import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/expiry_product/model/expired_product_details_model.dart';
import 'package:packer/features/views/expiry_product/model/expiry_product_model.dart';

class ExpiredProductController extends ChangeNotifier {
  var pageNumberAllProductList = 1;
  var hasNextPage = false;
  var expiryProductModel = <Results>[];
  var storeId = 0;
  ExpiredProductDetailsModel? productDetails;
  bool isLoading = false;

  Future<void> fetchExpiredProduct({
    bool fromBuild = false,
    bool isFirstTime = false,
  }) async {
    debugger();

    try {
      if (isLoading) return;
      isLoading = true;
      notifyListeners();

      if (isFirstTime) {
        pageNumberAllProductList = 1;
        hasNextPage = true;
        expiryProductModel.clear();
      }

      var paginatedUrl =
          "${AppUrls.expiryProductUrl}?page=$pageNumberAllProductList";
      if (storeId != 0) paginatedUrl += "&store_id=$storeId";

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: paginatedUrl,
      );

      final data = response.data;

      final List<dynamic> resultsData = data['results'] as List? ?? [];
      log("$resultsData");

      final newProducts = resultsData
          .map((item) => Results.fromJson(item))
          .whereType<Results>()
          .toList();

      //Pagination
      hasNextPage = data["has_next_page"] == true;

      pageNumberAllProductList = (data["page"] as int) + 1;

      // Add data to list
      expiryProductModel.addAll(newProducts);
    } catch (e) {
      log("Error fetching products: $e");
    } finally {
      notifyListeners();
    }
  }

  //details
  Future<void> fetchProductDetails(int productId) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.expiryProductDetailsUrl.replaceAll("id", "$productId"),
      );

      final data = response.data;

      productDetails = ExpiredProductDetailsModel.fromJson(data);
      notifyListeners();
    } catch (e) {
      print("Error fetching product: $e");
    }
  }
}
