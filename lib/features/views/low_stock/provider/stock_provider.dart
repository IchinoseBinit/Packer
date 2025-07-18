import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/extensions/list_extension.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/controllers/firebase_opt/firebase.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/carton/model/carton_list_model.dart';
import 'package:packer/features/views/low_stock/model/carton_model.dart';
import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/scanner/model/scan_result.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
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

  List<String> scannedCartonProductTagsList = [];

  late Box<TrolleyItem> box;
  late ProductDao dao;
  List<TrolleyItem> trolleyItems = [];
  LowStockModel? trolleyLowStockModel;




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

  Future<void> fetchLowStockProducts(BuildContext context) async {
    try {
      isLoading = true;
      isError = false;
      errorMessage = "";
      FirebaseAPI().cancelScheduledNotification();
      if (context.mounted) {
        notifyListeners();
      }
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

  /// Get carton info
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
        cartonModel = CartonModel.fromJson(response.data, code);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// FOR SCAN CARTON BUTTON
  ///
  /// EX Message: Scan 10 Cadburys
  void getMessageForCartonProduct(BuildContext context) {
    scannedCartonProductTagsList.clear();
    Provider.of<ScanMessageProvider>(context, listen: false).setMessage(context,
        "Scan ${cartonModel?.productUnits.length} ${cartonModel?.productName}");
  }

  /// Return TAGS scanned or remaining
  List<String> getTagsRemaining(bool remaining) {
    if (remaining) {
      // Return tags that have NOT been scanned
      return cartonModel?.productUnits
              .where((tag) => !scannedCartonProductTagsList.contains(tag))
              .toList() ??
          [];
    } else {
      // Return tags that HAVE been scanned
      return cartonModel?.productUnits
              .where((tag) => scannedCartonProductTagsList.contains(tag))
              .toList() ??
          [];
    }
  }

  /// Display TAGS scanned or remaining
  void showCartonProductTags(BuildContext context) {
    final remainingTags = getTagsRemaining(true);
    final completedTags = getTagsRemaining(false);
    // show modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: .8.sh,
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text("Product Tags"),
              ),
              // 12.h
              SizedBox(height: 12.h),
              if (remainingTags.isNotEmpty) ...[
                Text("Remaining Tags",
                    style: Theme.of(context).textTheme.labelLarge),
                // 12.h
                SizedBox(height: 12.h),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: remainingTags.length,
                    itemBuilder: (context, index) {
                      return Text(remainingTags[index],
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontSize: 13.sp,
                              ));
                    },
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 12.h);
                    },
                  ),
                ),
              ],
              // 12.h
              SizedBox(height: 12.h),
              if (completedTags.isNotEmpty) ...[
                Text("Completed Tags",
                    style: Theme.of(context).textTheme.labelLarge),
                // 12.h
                SizedBox(height: 12.h),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 12.h);
                    },
                    itemCount: completedTags.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                              child: Text(completedTags[index],
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.green,
                                        fontSize: 13.sp,
                                      ))),
                          const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Logic for scanning carton products
  ///
  /// [TODO]:
  // onScanCartonProduct(BuildContext context, String code)
  Future<ScanResult> onScanCartonProduct(
      BuildContext context, String code) async {
    try {
      // check if code is already scanned
      if (scannedCartonProductTagsList.contains(code)) {
        return ScanResult(success: false, message: 'Tag already scanned');
      }
      // check if code is from carton product units
      if (!cartonModel!.productUnits.contains(code)) {
        return ScanResult(success: false, message: 'Invalid tag');
      }
      scannedCartonProductTagsList.add(code);
      // check if required tags are scanned
      if (scannedCartonProductTagsList.length ==
          cartonModel!.productUnits.length) {
        // call api to post
        final result = await postCartonProductTags(context);
        if (result) {
          return ScanResult(success: true, message: 'Tag scanned successfully');
        } else {
          getMessageForCartonProduct(context);
          return ScanResult(success: false, message: 'Failed to scan tag');
        }
      }
      Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
          context,
          "Scan ${cartonModel!.productUnits.length - scannedCartonProductTagsList.length} ${cartonModel!.productName} more");
      return ScanResult(success: false);
    } catch (e) {
      return ScanResult(success: false, message: e.toString());
    }
  }

  /// Post carton product tags
  Future<bool> postCartonProductTags(BuildContext context) async {
    try {
      final url = AppUrls.postCartonProductTagsUrl;
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "carton_id": cartonModel!.cartonCode,
          "unit_tags": scannedCartonProductTagsList,
        },
      );
      if (response.statusCode == 200 && context.mounted) {
        navigateReplacement(context, route: NavigationConstants.dashboardRoute);
        return true;
      } else {
        return false;
      }
    } catch (ex) {
      return false;
    }
  }

  /// Updates the rack for a product of catron
  Future<bool> updateRack(
      BuildContext context, String code, int productId, bool isCarton) async {
    try {
      showLoading(context);
      final url = AppUrls.updateRackUrl;
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "rack_identifier": code,
          "product_id": productId,
          if (isCarton && cartonModel != null)
            "carton_identifier": cartonModel!.cartonCode,
        },
      );
      removeLoading(context);
      if (response.statusCode == 200 && context.mounted) {
        navigateReplacement(context, route: NavigationConstants.dashboardRoute);
        return true;
      } else {
        ErrorHandler.alertDialog(context, 'Failed to update rack');
        return false;
      }
    } catch (ex) {
      removeLoading(context);
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
        if (cartonModel != null && cartonModel!.productUnits.isNotEmpty) {
          if (context.mounted) {
            final result = await navigateReplacement(
              context,
              route: NavigationConstants.productScanScreenRoute,
              extra: {
                'productId': cartonModel!.productId,
                'forCarton': true,
              },
            );
            if (result ?? false) {
              navigatePop(context);
            }
            return true;
          }
        } else if (cartonModel != null && cartonModel!.rackName.isEmpty) {
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
              ShowAlertDialog(
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

  // update [LowStockModel] with trolley items if found the status change to ItemStatus.done
  void updateLowStockModel() {
    for (var element in selectedModel?.products ?? []) {
      for (var item in trolleyItems) {
        if (element.productId == item.productId) {
          element.scannedCount = item.quantity;
        }
      }
    }
    notifyListeners();
  }

  void onDetailsTaped(
    BuildContext context,
    LowStockModel lowStockModel,
  ) async {
    selectedModel = lowStockModel;
    initRackProductMap();
    basketId = "";
  
    box = await HiveDBService.openProductBox('store_${lowStockModel.storeId}');
    dao = ProductDao(box);

    if (context.mounted) {
      trolleyItems = dao.getAll();
      updateLowStockModel();
      navigate(context, route: NavigationConstants.lowStockDetailRoute);
      notifyListeners();
    }
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

  Future<ScanResult> checkBasketQr(BuildContext context, String code) async {
    scanMessage = "";
    notifyListeners();
    HapticFeedback.heavyImpact();

    try {
      final value = await postBasketCode(context, code);
      if (value) {
        basketId = code;
        return ScanResult(success: true);
      } else {
        return ScanResult(success: false);
      }
    } catch (e) {
      return ScanResult(success: false, message: e.toString());
    }
  }

  Future<bool> checkItemQr(BuildContext context, String code) async {
    try {
      if (scannedList.contains(code)) {
        ErrorHandler.alertDialog(context, "Tag Already scanned");

        return false;
      }
      if (selectedProduct?.quantity == scannedList.length) {
        ErrorHandler.alertDialog(context, "Product already scanned");
        return false;
      }
      if (!code.startsWith(selectedProduct?.productId.toString() ?? "")) {
        ErrorHandler.alertDialog(
            context, "Invalid QR ${detectQrMessage(code)}");
        return false;
      }
      scannedList.add(code);

      // final selProduct = selectedModel?.products.indexWhere(
      //     (element) => element.productId == selectedProduct?.productId);
      // if (selProduct != null && selProduct >= 0) {
      //   selectedModel?.products[selProduct].scannedCount++;
      // }
      selectedProduct!.scannedCount++;
      scanMessage =
          "Scan ${(selectedProduct?.quantity ?? 0) - (selectedProduct?.scannedCount ?? 0)} ${selectedProduct?.productName} More";

      if (scannedList.length == selectedProduct?.quantity) {
        await dao.addOrUpdateProduct(TrolleyItem(
          productId: selectedProduct!.productId,
          productName: selectedProduct!.productName,
          image: selectedProduct!.imageUrl,
          tags: scannedList,
          quantity: scannedList.length,
        ));

        trolleyItems = dao.getAll();
        scannedList = [];
        notifyListeners();
        return true;
        
      }
      notifyListeners();
      return false;
    } catch (e) {
      ErrorHandler.alertDialog(context, e.toString());
      return false;
    }
  }

  bool showCompleteButton() {
    if (selectedModel?.products == null) {
      return false;
    }
    // check with all trolley items.id with selected model products.id
    for (var element in trolleyItems) {
      if (!selectedModel!.products
          .any((product) => product.productId == element.productId)) {
        return false;
      }
    }
    return true;
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
      fetchLowStockProducts(context);
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
    scannedList = [];
    try {
      showLoading(context);
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.scanBasketUrl,
        body: {
          "basket_identifier": code,
        },
      );
      print("Basket Code: ${response.data}");
      removeLoading(context);
      if (response.statusCode == 200) {
        int storeId = response.data['store_id'].toString().toInt();
        trolleyLowStockModel = lowStockList.firstWhere((element) => element.storeId == storeId);
        box = await HiveDBService.openProductBox('store_$storeId');
        dao = ProductDao(box);
        trolleyItems = dao.getAll();
        return true;
      } else {
        ErrorHandler.alertDialog(context, "Failed to scan basket");
        return false;
      }
    } catch (e) {
      removeLoading(context);
      ErrorHandler.alertDialog(context, e.toString());
      return false;
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

  /// FOR TROLLEY Items
  /// 
  /// on scan trolley items
  Future<ScanResult> onScanTrolleyItems(BuildContext context, int productId, String code) async {
    try {
      // check if scannedList contains code
      // split code and check first part is productId
      if (code.split("-").first != productId.toString()) {
        return ScanResult(success: false, message: "Invalid QR - Product ID does not match");
      }
      if (scannedList.contains(code)) {
        return ScanResult(success: false, message: "Tag Already scanned");
      }
      final item = trolleyItems.firstWhereOrNull((element) => element.productId == productId);
      if (item == null) {
        return ScanResult(success: false, message: "Product not found");
      }
      if (!item.tags.contains(code)) {
        return ScanResult(success: false, message: "Tag not found");
      }
      scannedList.add(code);
      if (scannedList.length == item.quantity) {
        final result = await postTrolleyScannedTags(context, productId);
        scannedList = [];
        if (result) {
          trolleyItems = dao.getAll();
          notifyListeners();
          return ScanResult(success: true, message: "Scanned Successfully");
        }else {
          return ScanResult(success: false, message: "Failed to post scanned tags");
        }
      }
      Provider.of<ScanMessageProvider>(context, listen: false).setMessage(context, "Scan ${item.quantity - scannedList.length} ${item.productName}");
      notifyListeners();
      return ScanResult(success: false);
    } catch (e) {
      return ScanResult(success: false, message: e.toString());
    }
  }

  /// getMessageForTrolleyItem
  /// 
  /// example message: Scan 10 Cadburys
  Future<void> getMessageForTrolleyItem(BuildContext context, int productId) async {
    scannedList.clear();
    final product = trolleyItems.firstWhere((element) => element.productId == productId);
    var message = "Scan ${product.quantity} ${product.productName}";
    Provider.of<ScanMessageProvider>(context, listen: false).setMessage(context, message);
  }

  /// get tags of product in trolley whether scanned or not
  /// 
  /// return list of tags
  List<String> getTagsOfProductInTrolley(int productId, bool remaining) {
    final product = trolleyItems.firstWhere((element) => element.productId == productId);
    if (remaining) {
      return product.tags.where((element) => !scannedList.contains(element)).toList();
    } else {
      return product.tags.where((element) => scannedList.contains(element)).toList();
    }
  }

  // trolley item tag post
  Future<bool> postTrolleyScannedTags(BuildContext context, int productId) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.addProductsUrl,
        body: {
          "store_id": trolleyLowStockModel?.storeId,
          "product_units": scannedList,
          "basket_identifier": basketId,
        },
      );
      removeLoading(context);
      if (response.statusCode == 200 || response.statusCode == 201) {
        dao.deleteProduct(productId.toString());
        selectedModel?.products.removeWhere((element) => element.productId == productId);
        initRackProductMap();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      removeLoading(context);
      scannedList.clear();
      return false;
    } 
  }

  /// Display TAGS scanned or remaining
  void showTrolleyProductTags(BuildContext context, int productId) {
    final remainingTags = getTagsOfProductInTrolley(productId, true);
    final completedTags = getTagsOfProductInTrolley(productId, false);
    // show modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: .8.sh,
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text("Product Tags"),
              ),
              // 12.h
              SizedBox(height: 12.h),
              if (remainingTags.isNotEmpty) ...[
                Text("Remaining Tags",
                    style: Theme.of(context).textTheme.labelLarge),
                // 12.h
                SizedBox(height: 12.h),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: remainingTags.length,
                    itemBuilder: (context, index) {
                      return Text(remainingTags[index],
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontSize: 13.sp,
                              ));
                    },
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 12.h);
                    },
                  ),
                ),
              ],
              // 12.h
              SizedBox(height: 12.h),
              if (completedTags.isNotEmpty) ...[
                Text("Completed Tags",
                    style: Theme.of(context).textTheme.labelLarge),
                // 12.h
                SizedBox(height: 12.h),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 12.h);
                    },
                    itemCount: completedTags.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                              child: Text(completedTags[index],
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.green,
                                        fontSize: 13.sp,
                                      ))),
                          const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
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
