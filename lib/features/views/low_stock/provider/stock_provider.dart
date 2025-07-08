import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/extensions/list_extension.dart';
import 'package:packer/controllers/firebase_opt/firebase.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/carton/model/carton_list_model.dart';
import 'package:packer/features/views/low_stock/model/carton_model.dart';
import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class StockProvider extends ChangeNotifier {
  List<LowStockModel> lowStockList = [];
  bool isLoading = false;
  bool isError = false;
  String errorMessage = "";

  String scanMessage = "";

  LowStockModel? selectedModel;
  CartonModel? cartonModel;
  List<String> scannedList = [];
  List<int> completeProductId = [];
  ProductModel? selectedProduct;
  List<CartonListModel> cartonList = [];

  bool hasScanned = false;

  String basketId = "";
  List<String> rackNameList = [];
  Map<String, List<ProductModel>> rackProductMap = {};

  void initRackProductMap() {
    rackNameList.clear();
    rackProductMap.clear();

    selectedModel?.products.forEach((element) {
      if (!rackNameList.contains(element.rackName)) {
        rackNameList.add(element.rackName);
      }

      rackProductMap.putIfAbsent(element.rackName, () => []);
      rackProductMap[element.rackName]!.add(element);
    });

    rackNameList.sort((a, b) => a.compareTo(b));
    // TODO: Remove
    rackNameList = rackNameList.reversed.toList();
  }

  // reset
  void reset() {
    scannedList = [];
    isLoading = false;
    isError = false;
    errorMessage = "";
    scanMessage = "";
    rackNameList = [];
    rackProductMap = {};
  }

  bool checkScanCount(int productId) {
    final prod = selectedModel?.products
        .firstWhere((element) => element.productId == productId);
    return prod?.scannedCount == prod?.quantity;
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
      // for demo
      // await Future.delayed(const Duration(seconds: 2));
      // for (var item in demoData) {
      //   lowStockList.add(LowStockModel.fromJson(item));
      // }
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

  // update rack
  Future<bool> updateRack(
      BuildContext context, String code, int productId) async {
    try {
      final url = AppUrls.updateRackUrl;
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "rack_identifier": code,
          "product_id": productId,
        },
      );
      if (response.statusCode == 200 && context.mounted) {
        navigateReplacement(context, route: NavigationConstants.dashboardRoute);
        return true;
      } else {
        ErrorHandler.alertDialog(context, 'Failed to update rack');
        return false;
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
      return false;
    }
  }

  Future onScanCarton(BuildContext context, String code,
      {int? cartonId}) async {
    try {
      await callCartonInfoApi(context, code);
      if (cartonId != null && cartonModel != null) {
        final result = await navigateReplacement(
          context,
          route: NavigationConstants.productScanScreenRoute,
          extra: {
            'cartonId': cartonId,
            'productId': cartonModel!.productId,
          },
        );
        if (result ?? false) {
          navigatePop(context);
        }
        return true;
      } else {
        if (cartonModel != null && cartonModel!.rackName.isEmpty) {
          if (context.mounted) {
            final result = await navigateReplacement(context,
                route: NavigationConstants.scanRackRoute,
                extra: {
                  'forCarton': true,
                  'productId': cartonModel!.productId
                });
            if (result ?? false) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                navigateReplacement(context,
                    route: NavigationConstants.dashboardRoute);
              });
            }
            return true;
          }
        } else if (context.mounted) {
          navigateReplacement(
            context,
            route: NavigationConstants.scanRackRoute,
            extra: {
              'rack': cartonModel?.rackName,
            },
          );
          return true;
        }
      }
    } catch (e) {
      ErrorHandler.alertDialog(context, e.toString());
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
              await ShowAlertDialog(
                disableBackground: false,
                body: Text("Already Scanned"),
                okFunc: () {
                  navigatePop(context);
                },
              ).showAlertDialog(context);
              return false;
            }
            onProductDetailsTaped(context, matchedModel);
          }
        } else {
          ErrorHandler.alertDialog(context, "No Matching Product found");
          return false;
        }
      } else {
        ErrorHandler.alertDialog(context, "No Matching Carton found");
        return false;
      }
    } catch (e) {
      ErrorHandler.alertDialog(context, e.toString());
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
          }
        }
      }
    } catch (e) {
      ErrorHandler.alertDialog(context, e.toString());
      removeLoading(context);
    }
  }

  Future<void> fetchCartonList(BuildContext context, int productId) async {
    try {
      final url = AppUrls.cartonListUrl
          .replaceFirst('product_id', productId.toString());

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );

      if (response.statusCode == 200) {
        cartonList = (response.data as List)
            .map((item) => CartonListModel.fromJson(item))
            .toList();
      } else {
        return;
      }
    } catch (e) {
      log('Error fetching carton list: $e');
      rethrow;
    }
  }

  void onDetailsTaped(
    BuildContext context,
    LowStockModel lowStockModel,
  ) {
    selectedModel = lowStockModel;
    initRackProductMap();
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

  Future<bool> checkBasketQr(BuildContext context, String code) async {
    scanMessage = "";
    notifyListeners();
    HapticFeedback.heavyImpact();

    try {
      final value = await postBasketCode(context, code);
      if (value) {
        basketId = code;
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkItemQr(BuildContext context, String code) async {
    try {
      if (scannedList.contains(code)) {
        await ErrorHandler.alertDialog(context, "Tag Already scanned");
        return false;
      }
      if (selectedProduct?.quantity == scannedList.length) {
        await ErrorHandler.alertDialog(context, "Product already scanned");
        return false;
      }
      if (!code.startsWith(selectedProduct?.productId.toString() ?? "")) {
        await ErrorHandler.alertDialog(
            context, "Invalid QR ${detectQrMessage(code)}");
        return false;
      }

      scannedList.add(code);

      selectedProduct!.scannedCount++;
      scanMessage =
          "Scan ${(selectedProduct?.quantity ?? 0) - (selectedProduct?.scannedCount ?? 0)} ${selectedProduct?.productName} More";

      if (scannedList.length == selectedProduct?.quantity) {
        final response = await postScannedTags(context);
        if (response) {
          return true;
        } else {
          if (selectedProduct != null) {
            selectedProduct!.scannedCount = 0;
          }
          return false;
        }
      }
      notifyListeners();
      return false;
    } catch (e) {
      await ErrorHandler.alertDialog(context, e.toString());
      return false;
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

  Future<bool> postScannedTags(BuildContext context) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.addProductsUrl,
        body: {
          "store_id": selectedModel?.storeId,
          "product_units": scannedList,
          "basket_identifier": basketId,
        },
      );
      if (response.statusCode == 200) {
        completeProductId.add(selectedProduct?.productId ?? 0);
        showToast("Scanned Successfully");
        removeLoading(context);
        return true;
      } else {
        ErrorHandler.alertDialog(context, "Failed to scan basket");
        return false;
      }
    } catch (e) {
      scannedList.clear();

      removeLoading(context);
      rethrow;
    } finally {
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
      ErrorHandler.alertDialog(context, e.toString());
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
        ErrorHandler.alertDialog(context, "Failed to scan basket");
        return false;
      }
    } catch (e) {
      ErrorHandler.alertDialog(context, e.toString());
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

  Future<bool> scanRack(BuildContext context, String code) async {
    if (cartonModel != null) {
      if (cartonModel!.rackName.isEmpty) {
        final result = await updateRack(context, code, cartonModel!.productId);
        return result;
      } else if (code
          .toLowerCase()
          .contains(cartonModel!.rackName.toLowerCase())) {
        showToast("Rack scanned successfully");

        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   navigateReplacement(context,
        //       route: NavigationConstants.dashboardRoute);
        // });
        return true;
      } else {
        ErrorHandler.alertDialog(context, "Invalid rack");
        return false;
      }
    } else {
      ErrorHandler.alertDialog(context, "No data found");
      return false;
    }
  }

  // Future<bool> updateRack(
  //     BuildContext context, String code, int productId) async {
  //   try {
  //     final url = AppUrls.updateRackUrl;
  //     final response = await DioClient().request(
  //       requestType: RequestType.postWithToken,
  //       url: url,
  //       body: {
  //         "rack_identifier": code,
  //         "product_id": productId,
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       // debugger();
  //       showToast("Rack updated successfully");
  //       // WidgetsBinding.instance.addPostFrameCallback((_) {
  //       //   navigateAndRemoveAll(context,
  //       //       route: NavigationConstants.dashboardRoute);
  //       // });
  //       return true;
  //     } else {
  //       showToast('Failed to update rack');
  //       return false;
  //       // navigateAndRemoveAll(context,
  //       //     route: NavigationConstants.dashboardRoute);
  //     }
  //   } catch (ex) {
  //     showToast(ex.toString());
  //     return false;
  //     // showDialog(
  //     //   context: context,
  //     //   builder: (context) => AlertDialog(
  //     //     title: Row(
  //     //       children: [
  //     //         Icon(Icons.error, color: Colors.red),
  //     //         SizedBox(width: 8),
  //     //         Text(
  //     //           "Product Availability Failed",
  //     //           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
  //     //                 fontSize: 12.sp,
  //     //                 fontWeight: FontWeight.w400,
  //     //               ),
  //     //         ),
  //     //       ],
  //     //     ),
  //     //     content: Column(
  //     //       mainAxisSize: MainAxisSize.min,
  //     //       children: [
  //     //         Text("Do you want to scan again?"),
  //     //         SizedBox(height: 20),
  //     //         Row(
  //     //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     //           children: [
  //     //             TextButton(
  //     //               onPressed: () {
  //     //                 Navigator.of(context).pop(); // Close dialog
  //     //                 navigate(context,
  //     //                     route: NavigationConstants.qrScanScreenRoute,
  //     //                     extra: {
  //     //                       'scanCarton': true,
  //     //                     });
  //     //               },
  //     //               child: Text("Yes"),
  //     //             ),
  //     //             TextButton(
  //     //               onPressed: () {
  //     //                 Navigator.of(context).pop(); // Close dialog
  //     //                 navigate(context,
  //     //                     route: NavigationConstants.dashboardRoute);
  //     //               },
  //     //               child: Text("No"),
  //     //             ),
  //     //           ],
  //     //         )
  //     //       ],
  //     //     ),
  //     //   ),
  //     // );
  //   }
  // }
}
