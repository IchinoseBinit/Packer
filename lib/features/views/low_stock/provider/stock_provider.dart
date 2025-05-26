import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/firebase_opt/firebase.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/low_stock/model/carton_model.dart';
import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';

class StockProvider extends ChangeNotifier {
  List<LowStockModel> lowStockList = [];
  bool isLoading = false;
  bool isError = false;
  String errorMessage = "";

  String scanMessage = "";
  bool hasScanned = false;

  LowStockModel? selectedModel;
  CartonModel? cartonModel;
  List<String> scannedList = [];
  ProductModel? selectedProduct;

  // reset
  void reset() {
    scannedList = [];
    isLoading = false;
    isError = false;
    errorMessage = "";
    scanMessage = "";
  }

  bool checkScanCount(int productId) {
    for (ProductModel element in selectedModel?.products ?? []) {
      if (element.productId == productId) {
        // get from scanned data list split by -
        if (element.scannedCount == element.quantity) {
          return true;
        }
      }
    }
    return false;
  }

  int getScanCount(int productId) {
    for (ProductModel element in selectedModel?.products ?? []) {
      if (element.productId == productId) {
        // get from scanned data list split by -
        return element.quantity - element.scannedCount;
      }
    }
    return 0;
  }

  void fetchLowStockProducts() async {
    try {
      isLoading = true;
      isError = false;
      errorMessage = "";
      FirebaseAPI().cancelScheduledNotification();
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.lowStockUrl,
      );
      if (response.statusCode == 200) {
        lowStockList = [];
        for (var item in response.data) {
          lowStockList.add(LowStockModel.fromJson(item));
        }
      } else {
        isError = true;
        errorMessage = "No data found";
      }
      FirebaseAPI().scheduleNotification();
    } catch (e) {
      isError = true;
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void onScanCarton(BuildContext context, String code) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.cartonInfoUrl.replaceAll(':id', code),
      );
      log("Carton Info: ${response.statusCode}");
      removeLoading(context);
      if (response.statusCode == 200) {
        cartonModel = CartonModel.fromJson(response.data);
        if (cartonModel != null && cartonModel!.rackName.isEmpty) {
          showYesNo(context).then((value) {
            if (value == true) {
              navigate(context,
                  route: NavigationConstants.scanRackRoute,
                  extra: {
                    'cartonProduct': true,
                    'message': '${cartonModel?.productName} - Assign a rack',
                  });
            }
          });
        } else {
          navigate(context, route: NavigationConstants.scanRackRoute, extra: {
            "cartonProduct": true,
            'rack': cartonModel?.rackName,
          });
        }
      } else {
        showToast("No data found");
      }
    } catch (e) {
      showToast(e.toString());
      removeLoading(context);
    }
  }

  void onDetailsTaped(
    BuildContext context,
    LowStockModel lowStockModel,
  ) {
    selectedModel = lowStockModel;
    navigate(
      context,
      route: NavigationConstants.lowStockScannerRoute,
      extra: {"forProduct": false},
    );
  }

  void onProductDetailsTaped(BuildContext context, ProductModel model) {
    scannedList = [];
    selectedProduct = model;
    scanMessage = "Scan ${model.quantity} ${model.productName} ";
    navigate(
      context,
      route: NavigationConstants.lowStockScannerRoute,
      extra: {"forProduct": true},
    );
  }

  void checkBasketQr(BuildContext context, MobileScannerController? controller,
      String code) async {
    if (hasScanned) {
      return;
    }
    hasScanned = true;
    controller?.stop();
    scanMessage = "";
    notifyListeners();
    HapticFeedback.heavyImpact();

    try {
      final value = await postBasketCode(context, code);
      if (value) {
        navigateReplacement(context,
            route: NavigationConstants.lowStockDetailRoute);
        hasScanned = false;
      } else {
        controller?.start();
        hasScanned = false;
        return;
      }
    } catch (e) {
      _handleInvalidQR(context, controller);
      hasScanned = false;
      return;
    }
  }

  void checkItemQr(BuildContext context, MobileScannerController? controller,
      String code) async {
    if (hasScanned) {
      return;
    }
    hasScanned = true;
    controller?.stop();
    HapticFeedback.heavyImpact();

    try {
      if (scannedList.contains(code)) {
        showToast("Tag Already scanned");
        controller?.start();
        hasScanned = false;
        return;
      }
      if (selectedProduct?.quantity == scannedList.length) {
        showToast("Product already scanned");
        controller?.start();
        hasScanned = false;
        return;
      }
      if (!code.startsWith(selectedProduct?.productId.toString() ?? "")) {
        showToast("Invalid QR");
        controller?.start();
        hasScanned = false;
        return;
      }
      scannedList.add(code);
      for (ProductModel element in selectedModel?.products ?? []) {
        if (element.productId == selectedProduct?.productId) {
          element.scannedCount++;
        }
      }
      scanMessage =
          "Scan ${(selectedProduct?.quantity ?? 0) - (selectedProduct?.scannedCount ?? 0)} ${selectedProduct?.productName} More";
      notifyListeners();
      if (scannedList.length == selectedProduct?.quantity) {
        postScannedTags(context);
        hasScanned = false;
      } else {
        controller?.start();
        hasScanned = false;
      }
    } catch (e) {
      _handleInvalidQR(context, controller);
      hasScanned = false;
      return;
    }
  }

  bool showCompleteButton() {
    if (selectedModel?.products == null) {
      return false;
    }
    for (ProductModel element in selectedModel?.products ?? []) {
      if (element.scannedCount != element.quantity) {
        return false;
      }
    }
    return true;
  }

  void postScannedTags(BuildContext context) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.addProductsUrl,
        body: {
          "store_id": selectedModel?.storeId,
          "product_units": scannedList,
        },
      );
      if (response.statusCode == 200) {
        showToast("Scanned Successfully");
      } else {
        showToast("Failed to scan basket");
      }
    } catch (e) {
      showToast(e.toString());
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        removeLoading(context);
        navigatePop(context);
      });
      scannedList = [];
    }
  }

  void transferBasket(BuildContext context) async {
    try {
      // final response = await DioClient().request(
      //   requestType: RequestType.postWithToken,
      //   url: AppUrls.transferBasketInventoryUrl,
      // );
      // if (response.statusCode == 200) {

      // } else {
      //   showToast("Failed to scan basket");
      // }

      showToast("Transferred Successfully");
      lowStockList.remove(selectedModel);
      notifyListeners();
      if (lowStockList.isEmpty) {
        fetchLowStockProducts();
      }
      navigatePop(context);
    } catch (e) {
      showToast(e.toString());
    }
  }

  void _handleInvalidQR(
      BuildContext context, MobileScannerController? controller) {
    removeLoading(context);
    ShowAlertDialog(
      body: const Text("Invalid QR"),
      okFunc: () {
        Navigator.pop(context);
        controller?.start();
      },
    ).showAlertDialog(context);
  }

  Future<bool> postBasketCode(BuildContext context, String code) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.scanBasketUrl,
        body: {
          "basket_identifier": code,
        },
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        showToast("Failed to scan basket");
        return false;
      }
    } catch (e) {
      showToast(e.toString());
      return false;
    } finally {
      removeLoading(context);
    }
  }

  Future<bool?> showYesNo(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: const Text("Do you want to assign a rack?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void scanRack(BuildContext context, MobileScannerController? controller,
      String code) async {
    if (hasScanned) {
      return;
    }
    hasScanned = true;
    if (cartonModel != null) {
      if (cartonModel!.rackName.isEmpty) {
        final value = await updateRack(context, code, cartonModel!.productId);
        if (value) {
          hasScanned = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigateReplacement(context,
                route: NavigationConstants.dashboardRoute);
          });
        } else {
          controller?.start();
          hasScanned = false;
        }
      } else if (code
          .toLowerCase()
          .contains(cartonModel!.rackName.toLowerCase())) {
        showToast("Rack scanned successfully");
        navigatePop(context);
        hasScanned = false;
      } else {
        controller?.start();
        hasScanned = false;
        showToast("Invalid rack");
      }
    } else {
      showToast("No data found");
      navigatePop(context);
      hasScanned = false;
    }
  }

  Future<bool> updateRack(
      BuildContext context, String code, int productId) async {
    try {
      // show loading
      showLoading(context);
      final url = AppUrls.updateRackUrl;
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "rack_identifier": code,
          "product_id": productId,
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        removeLoading(context);
      });

      if (response.statusCode == 200) {
        showToast("Rack updated successfully");
        return true;
      } else {
        showToast('Failed to update rack');
        return false;
      }
    } catch (ex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        removeLoading(context);
        showToast(ex.toString());
      });
      return false;
    }
  }
}
