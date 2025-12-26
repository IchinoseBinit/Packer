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

  // rackList, rackProductMap
  List<String> rackList = [];
  Map<String, List<Results>> rackProductMap = {};

  void arrangeItemAccordingToRack() {
    rackList = expiryProductModel.map((e) => e.rackName).toSet().toList();
    rackProductMap = {};
    for (var rack in rackList) {
      rackProductMap[rack] =
          expiryProductModel.where((e) => e.rackName == rack).toList() ?? [];
    }
    // sort rack list
    rackList.sort((a, b) => a.compareTo(b));
    notifyListeners();
  }

  Future<void> fetchExpiredProduct({bool isFirstTime = false}) async {
    if (isLoading || isPaginationLoading) return;

    if (!isFirstTime && !hasNextPage) return;

    try {
      if (isFirstTime) {
        _page = 1;
        hasNextPage = true;
        expiryProductModel.clear();
        isLoading = true;
      } else {
        isPaginationLoading = true;
      }

      notifyListeners();

      final paginated = await _repo.fetchProductsPage(_page);

      // Add new data
      expiryProductModel.addAll(paginated.results);
      arrangeItemAccordingToRack();

      hasNextPage = paginated.hasNextPage;

      // Move to next page ONLY if available
      if (hasNextPage) {
        _page++;
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
