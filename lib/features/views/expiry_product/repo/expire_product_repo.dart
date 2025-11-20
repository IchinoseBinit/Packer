// import 'dart:developer';
// import 'package:packer/constants/app_urls.dart';
// import 'package:packer/controllers/api/dio_client.dart';
// import 'package:packer/controllers/services/api/enum/request_type.dart';
// import 'package:packer/features/views/expiry_product/model/expiry_product_model.dart';


// class ExpiredProductRepository {
//   int pageNumberAllProductList = 1;
//   bool hasNextPage = true;
//   bool isLoading = false;
//   final List<Results> expiryProductModel = [];

//   /// Fetch expired products with pagination
//   Future<void> fetchExpiredProduct({
//     bool isFirstTime = false,
//     int? storeId,
//   }) async {
//     if (isLoading) return;

//     try {
//       _setLoading(true);

//       if (isFirstTime) _resetPagination();

//       // Fetch current page
//       final newProducts = await fetchProductsPage(
//         page: pageNumberAllProductList,
//         storeId: storeId,
//       );

//       expiryProductModel.addAll(newProducts);

//       // Update pagination
//       if (newProducts.isEmpty) {
//         hasNextPage = false;
//       } else {
//         pageNumberAllProductList += 1;
//       }

//       log("Fetched products: ${newProducts.length}");
//     } catch (e, st) {
//       log("Error fetching expired products: $e\n$st");
//     } finally {
//       _setLoading(false);
//     }
//   }

//   /// Internal: Fetch a single page of products
//   Future<List<Results>> fetchProductsPage(int pageNumberAllProductList, {
//     required int page,
//     int? storeId,
//   }) async {
//     try {
//       final url = _buildPaginatedUrl(page: page, storeId: storeId);

//       final response = await DioClient().request(
//         requestType: RequestType.getWithToken,
//         url: url,
//       );

//       final data = response.data;
//       final resultsData = (data['results'] as List?) ?? [];

//       return resultsData
//           .map((item) => Results.fromJson(item))
//           .whereType<Results>()
//           .toList();
//     } catch (e, st) {
//       log("Error fetching products page: $e\n$st");
//       return [];
//     }
//   }

//   /// Internal: Build paginated URL
//   String _buildPaginatedUrl({required int page, int? storeId}) {
//     var url = "${AppUrls.expiryProductUrl}?page=$page";
//     if (storeId != null && storeId != 0) {
//       url += "&store_id=$storeId";
//     }
//     return url;
//   }

//   /// Internal: Set loading state
//   void _setLoading(bool value) {
//     isLoading = value;
//     // notifyListeners(); // Uncomment if using ChangeNotifier
//   }

//   /// Internal: Reset pagination and data
//   void _resetPagination() {
//     pageNumberAllProductList = 1;
//     hasNextPage = true;
//     expiryProductModel.clear();
//   }
// }
