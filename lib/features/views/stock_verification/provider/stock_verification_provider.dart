import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/stock_verification/model/stock_item_model.dart';
import 'package:provider/provider.dart';

class StockVerificationProvider extends ChangeNotifier {
  bool isLoading = false;

  List<StockItemModel> stockItems = [];

  StockItemModel? selectedStockItem;

  List<String> scannedUnits = [];

  // fetch
  Future<void> fetchStockItems() async {
    try {
      isLoading = true;
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.getStockItemsUrl,
      );
      stockItems =
          response.data.map((e) => StockItemModel.fromJson(e)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> onItemTap(BuildContext context, StockItemModel item) async {
    selectedStockItem = item;
    if (selectedStockItem != null) {
      if (selectedStockItem!.rackName != null) {
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
                "productUnits": selectedStockItem!.productUnits
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
  Future<bool> onScanProduct(
      BuildContext context, int productId, String code) async {
    if (selectedStockItem?.productId == productId) {
      if (selectedStockItem!.productUnits.contains(code)) {
        if (scannedUnits.contains(code)) {
          return false;
        } else {
          scannedUnits.add(code);
        }
      }
      // check for the remaining or not
      if (scannedUnits.length == selectedStockItem!.productUnits.length) {
        final result = await onVerify(context, productId, scannedUnits);
        return result;
      } else {
        final scanMessage =
            "Scan ${selectedStockItem!.productUnits.length - scannedUnits.length} more units";
        Provider.of<ScanMessageProvider>(context, listen: false)
            .setMessage(scanMessage);
      }
    }
    return false;
  }

  Future<bool> onVerify(
      BuildContext context, int productId, List<String> productUnits) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.stockVerificationUrl,
        body: {"product": productId, "product_units": productUnits},
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
