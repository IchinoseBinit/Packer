import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/stock_verification/model/stock_item_model.dart';
import 'package:packer/features/views/stock_verification/model/store_model.dart';
import 'package:provider/provider.dart';

class StockVerificationProvider extends ChangeNotifier {
  bool isLoading = false;

  List<StockItemModel> stockItems = [];
  List<String> rackList = [];
  Map<String, List<StockItemModel>> rackProductMap = {};

  StockItemModel? selectedStockItem;

  List<String> scannedUnits = [];
  Store? selectedStore;

  List<Store> storeList = [];

  void arrangeStockItems() {
    rackList.clear();
    rackProductMap.clear();
    for (var element in stockItems) {
      if (!rackList.contains(element.rackName)) {
        rackList.add(element.rackName);
      }
      if (rackProductMap.containsKey(element.rackName)) {
        rackProductMap[element.rackName]!.add(element);
      } else {
        rackProductMap[element.rackName] = [element];
      }
    }

    // sort
    rackList.sort((a, b) => a.compareTo(b));
    notifyListeners();
  }

  Future<void> fetchStores() async {
    try {
      if (storeList.isNotEmpty) {
        return;
      }
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.getStoreUrl,
      );
      storeList =
          (response.data as List).map((e) => Store.fromJson(e)).toList();

      notifyListeners();
    } catch (e) {
      log("Error while getting value $e");
      notifyListeners();
    }
  }

  // fetch
  Future<void> fetchStockItems(String storeId) async {
    try {
      isLoading = true;
      rackList.clear();
      rackProductMap.clear();
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.getStockItemsUrl.replaceAll("value", storeId),
      );
      stockItems = (response.data as List)
          .map((e) => StockItemModel.fromJson(e))
          .toList();
      isLoading = false;
      arrangeStockItems();
    } catch (e) {
      log("Error while getting value $e");
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> onItemTap(BuildContext context, StockItemModel item) async {
    selectedStockItem = item;
    scannedUnits.clear();
    if (selectedStockItem != null) {
      if (selectedStockItem!.rackName.isNotEmpty) {
        final result = await navigate(context,
            route: NavigationConstants.scanRackRoute,
            extra: {
              "rack": selectedStockItem!.rackName,
              "productId": selectedStockItem!.productId
            });

        if (result ?? false) {
          // sacn product
          final scanResults = await navigate(context,
              route: NavigationConstants.productScanScreenRoute,
              extra: {
                "productId": selectedStockItem!.productId,
                "productUnits": selectedStockItem!.productUnits,
                "fromStockVerification": true,
              });
          if (scanResults ?? false) {
            // sacn product
          }
        }
      } else {
        // scan product
        final result = await navigate(context,
            route: NavigationConstants.productScanScreenRoute,
            extra: {
              "productId": selectedStockItem!.productId,
              "fromStockVerification": true,
            });
        if (result ?? false) {
          // sacn product
        }
      }
    }
  }

  // onScanProduct
  bool onScanProduct(BuildContext context, int productId, String code,
      {bool fromStockVerification = false}) {
    if (selectedStockItem?.productId == productId) {
      if (scannedUnits.contains(code)) {
        return false;
      } else {
        scannedUnits.add(code);
      }

      if (fromStockVerification) {
        final quantity = scannedUnits.length;

        var message = "Scan Product Code";
        if (quantity > 0) {
          message += " Scanned $quantity units";
        }
        Provider.of<ScanMessageProvider>(context, listen: false)
            .setMessage(message);
      } else {
        // check for the remaining or not
        var scanMessage = "";
        if (scannedUnits.length >= selectedStockItem!.productUnits.length) {
          scanMessage = "Scanned ${scannedUnits.length} units";
        } else {
          scanMessage =
              "Scan ${selectedStockItem!.productUnits.length - scannedUnits.length} more units";
        }
        Provider.of<ScanMessageProvider>(context, listen: false)
            .setMessage(scanMessage);
      }

      notifyListeners();

      return true;
    }
    return false;
  }

  // This should only be called when the button on the ui is clicked.
  // The button would only be visible when the scanned units are equal to the product units.
  // The person can scan other units as well but the button would not be visible.
  Future<bool> onVerify(int productId, List<String> productUnits) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.stockVerificationUrl,
        body: {
          "product": productId,
          "product_units": productUnits,
          "planned_quantity": selectedStockItem!.plannedQuantity,
          "store_id": selectedStore?.id,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        stockItems.remove(selectedStockItem!);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
