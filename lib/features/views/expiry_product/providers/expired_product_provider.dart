import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:packer/features/views/expiry_product/models/expired_product_details_model.dart';
import 'package:packer/features/views/expiry_product/models/expiry_product_model.dart';
import 'package:packer/features/views/expiry_product/repositories/expired_product_repository.dart';

class ExpiredProductProvider extends ChangeNotifier {
  final ExpiredProductRepository _repo = ExpiredProductRepository();

  int _page = 1;

  bool hasNextPage = false;
  bool isLoading = false;
  bool isPaginationLoading = false;

  List<Results> expiryProductModel = [];
  ExpiredProductDetailsModel? productDetails;

  /// Fetch products
  Future<void> fetchExpiredProduct({bool isFirstTime = false}) async {
    if (isLoading || isPaginationLoading) return;

    try {
      if (isFirstTime) {
        isLoading = true;
        _page = 1;
        expiryProductModel.clear();
      } else {
        isPaginationLoading = true;
      }

      notifyListeners();

      // Fetch paginated products
      final paginated = await _repo.fetchProductsPage(_page);

      expiryProductModel.addAll(paginated.results);

      hasNextPage = paginated.hasNextPage;

      if (hasNextPage) {
        _page = paginated.page + 1;
      }
    } catch (e, s) {
      log("Error fetching products: $e\n$s");
    } finally {
      isLoading = false;
      isPaginationLoading = false;
      notifyListeners();
    }
  }

  /// Remove scanned tag
  void removeScannedTag(String tag) {
    expiryProductModel.removeWhere((product) {
      product.unitTags.remove(tag);
      return product.unitTags.isEmpty;
    });

    notifyListeners();
  }

  /// Fetch product details
  Future<void> fetchProductDetails(int productId) async {
    try {
      productDetails = await _repo.fetchProductDetails(productId);
      notifyListeners();
    } catch (e) {
      log("Error fetching product details: $e");
    }
  }
}
