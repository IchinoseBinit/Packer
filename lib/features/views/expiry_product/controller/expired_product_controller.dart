// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:packer/constants/app_urls.dart';
// import 'package:packer/controllers/api/dio_client.dart';
// import 'package:packer/controllers/services/api/enum/request_type.dart';
// import 'package:packer/features/views/expiry_product/models/expired_product_details_model.dart';
// import 'package:packer/features/views/expiry_product/models/expiry_product_model.dart';

// import 'package:packer/features/views/expiry_product/repo/expire_product_repo.dart';

// class ExpiredProductController extends ChangeNotifier {
//   var pageNumberAllProductList = 1;
//   var hasNextPage = false;
//   var expiryProductModel = <Results>[];
//   var storeId = 0;
//   ExpiredProductDetailsModel? productDetails;
//   bool isLoading = false;
//   bool isPaginationLoading = false;

//   Future<void> fetchExpiredProduct({
//     bool fromBuild = false,
//     bool isFirstTime = false,
//   }) async {
//     try {
//       if (isLoading) return;
//       isLoading = true;
//       notifyListeners();

//       if (isFirstTime) {
//         pageNumberAllProductList = 1;
//         hasNextPage = true;
//         expiryProductModel.clear();
//       }

     
//       final pageResponse = await ExpiredProductRepository()
//           .fetchExpiredProductsPage(page: pageNumberAllProductList);

//       final data = pageResponse.data;
//       final newProducts = pageResponse.products;

//       //Pagination
//       if (hasNextPage = data["has_next_page"] == true) {
//         pageNumberAllProductList = (data["page"] as int) + 1;
//         isPaginationLoading = true;
//       } else {
//         isPaginationLoading = false;
//       }

//       expiryProductModel.addAll(newProducts);
//       isLoading = false;
//     } catch (e) {
//       log("Error fetching products: $e");
//       isLoading = false;
//     } finally {
//       notifyListeners();
//     }
//   }

//   void removeScannedTag(String scannedTag) {
//     for (var product in expiryProductModel) {
//       if (product.unitTags.contains(scannedTag)) {
//         product.unitTags.remove(scannedTag);

//         // If no more unit tags left, remove the product from list
//         if (product.unitTags.isEmpty) {
//           expiryProductModel.remove(product);
//         }

//         notifyListeners();
//         return;
//       }
//     }
//   }

//   //details
//   Future<void> fetchProductDetails(int productId) async {
//     try {
//       final response = await DioClient().request(
//         requestType: RequestType.getWithToken,
//         url: AppUrls.expiryProductDetailsUrl.replaceAll("id", "$productId"),
//       );

//       final data = response.data;

//       productDetails = ExpiredProductDetailsModel.fromJson(data);
//       notifyListeners();
//     } catch (e) {
//       print("Error fetching product: $e");
//     }
//   }
// }
