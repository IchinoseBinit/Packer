import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/extensions/list_extension.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
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

  LowStockModel? selectedModel;
  CartonModel? cartonModel;
  List<String> scannedList = [];
  ProductModel? selectedProduct;

  bool hasScanned = false;

  String basketId = "";

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

  Future<void> fetchLowStockProducts() async {
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

  Future callCartonInfoApi(BuildContext context, String code) async {
    try {
      // debugger();
      showLoading(context);
      if (!code.contains("carton")) {
        throw "Invalid Carton QR";
      }
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.cartonInfoUrl.replaceAll(':id', code),
      );
      log("Carton Info: ${response.statusCode}");

      if (context.mounted) {
        removeLoading(context);
      }
      if (response.statusCode == 200) {
        cartonModel = CartonModel.fromJson(response.data);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future onScanCarton(BuildContext context, String code) async {
    try {
      await callCartonInfoApi(context, code);

      if (cartonModel != null && cartonModel!.rackName.isEmpty) {
        if (context.mounted) {
          navigateReplacement(context,
              route: NavigationConstants.scanRackRoute,
              extra: {
                'cartonProduct': true,
                'message': '${cartonModel?.productName} - Assign a rack',
              });
        }
      } else {
        navigateReplacement(
          context,
          route: NavigationConstants.scanRackRoute,
          extra: {
            "cartonProduct": true,
            'rack': cartonModel?.rackName,
          },
        );
      }
    } catch (e) {
      showToast(e.toString());
      removeLoading(context);
      return false;
    }
  }

  Future lowStockCartonScan(BuildContext context, String code) async {
    try {
      await callCartonInfoApi(context, code);

      if (cartonModel != null) {
        final matchedModel = selectedModel?.products.firstWhereOrNull(
            (element) => element.productId == cartonModel!.productId);

        if (matchedModel != null) {
          if (matchedModel.productId == cartonModel!.productId) {
            if (checkScanCount(matchedModel.productId)) {
              return;
            }
            onProductDetailsTaped(context, matchedModel);
          }
        } else {
          showToast("No Matching Product found");
          return false;
        }
      } else {
        showToast("No Matching Carton found");
        return false;
      }
    } catch (e) {
      showToast(e.toString());
      removeLoading(context);
      return false;
    }
  }

  void verifyCarton(BuildContext context, String code, String productId) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        body: {
          "unique_identifier": code,
          "product_id": productId,
        },
        url: AppUrls.verifyCartonUrl,
      );
      log("Carton Info: ${response.statusCode}");

      if (context.mounted) {
        removeLoading(context);
      }
      if (response.statusCode == 200) {
        if (lowStockList.isNotEmpty) {
          final matchedModel = lowStockList.firstWhere(
            (element) => element.products.any(
              (product) => product.productId.toString() == productId,
            ),
          );
          if (matchedModel.products.isNotEmpty) {
            log("CartonfffffffffffInfo: $productId");

            navigate(context,
                route: NavigationConstants.productqrScreenRoute,
                extra: {
                  'cartItem': true,
                  'productId': productId.toInt(),
                });
          }
        }
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
    basketId = "";
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
    navigateReplacement(
      context,
      route: NavigationConstants.lowStockScannerRoute,
      extra: {"forProduct": true},
    );
  }

  void checkBasketQr(BuildContext context, MobileScannerController? controller,
      String code) async {
    if (hasScanned) return;
    hasScanned = true;
    controller?.stop();
    scanMessage = "";
    notifyListeners();
    HapticFeedback.heavyImpact();

    try {
      final value = await postBasketCode(context, code);
      if (value) {
        basketId = code;
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
    if (hasScanned) return;
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
      } else {
        controller?.start();
      }
      hasScanned = false;
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
      removeLoading(context);
      navigatePop(context);
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
      navigatePop(context);
      fetchLowStockProducts();
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
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: const Text("Assign a rack?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }

  void scanRack(
      BuildContext context, MobileScannerController? controller, String code) {
    if (hasScanned) return;
    hasScanned = true;
    // debugger();
    if (cartonModel != null) {
      if (cartonModel!.rackName.isEmpty) {
        updateRack(context, code, cartonModel!.productId);
      } else if (code
          .toLowerCase()
          .contains(cartonModel!.rackName.toLowerCase())) {
        showToast("Rack scanned successfully");
        hasScanned = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigateReplacement(context,
              route: NavigationConstants.dashboardRoute);
        });
      } else {
        controller?.start();

        showToast("Invalid rack");
        hasScanned = false;
      }
    } else {
      showToast("No data found");
      navigatePop(context);
      hasScanned = false;
    }
  }

  void updateRack(BuildContext context, String code, int productId) async {
    try {
      // debugger();
      showToast("Updating rack...");
      final url = AppUrls.updateRackUrl;
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "rack_identifier": code,
          "product_id": productId,
          // "store_id": "selectedTransferModel?.storeId",
        },
      );

      if (response.statusCode == 200) {
        // debugger();
        showToast("Rack updated successfully");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigateAndRemoveAll(context,
              route: NavigationConstants.dashboardRoute);
        });
      } else {
        showToast('Failed to update rack');
        // navigateAndRemoveAll(context,
        //     route: NavigationConstants.dashboardRoute);
      }
    } catch (ex) {
      showToast(ex.toString());
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text(
                "Product Availability Failed",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Do you want to scan again?"),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      navigate(context,
                          route: NavigationConstants.qrScanScreenRoute,
                          extra: {
                            'scanCarton': true,
                          });
                    },
                    child: Text("Yes"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      navigate(context,
                          route: NavigationConstants.dashboardRoute);
                    },
                    child: Text("No"),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    }
  }
}
