import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/extensions/list_extension.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/controllers/firebase_opt/firebase.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/hive_db/hive_db_service.dart';
import 'package:packer/controllers/services/hive_db/product_dao.dart';
import 'package:packer/controllers/services/hive_db/trolley_item.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/carton/model/carton_list_model.dart';
import 'package:packer/features/views/low_stock/model/carton_model.dart';
import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/scanner/model/scan_result.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/product_tag_sheet.dart';
import 'package:provider/provider.dart';

class StockProvider extends ChangeNotifier {
  /// === STATE VARIABLES START ===
  List<LowStockModel> lowStockList =
      []; // List of low stock items [main_store dashboard]
  bool isLoading = false; // Loading state [main_store dashboard]
  bool isError = false; // Error state [main_store dashboard]
  String errorMessage = ""; // Error message [main_store dashboard]

  String scanMessage = ""; // Scan message for scanner screen

  LowStockModel? selectedModel; // Selected low stock model from dashboard
  CartonModel? cartonModel; // assign carton model after scanning carton code
  List<String> scannedList = []; // List of scanned items
  ProductModel?
      selectedProduct; // assign product model after carton model matches product

  String basketId =
      ""; // Holds the basket identifier for tranfering trolley items to basket

  // FOR Item Screen
  List<String> rackNameList = [];
  Map<String, List<ProductModel>> rackProductMap = {};

  late Box<TrolleyItem> box; // Open box for trolley items [local db]
  late ProductDao dao; // Initialize dao for trolley items [local db]
  List<TrolleyItem> trolleyItems =
      []; // Get all trolley items [local db] for selected store
  LowStockModel? trolleyLowStockModel; // Assign from collected product View

  /// === STATE VARIABLES END ===

  /// === METHODS START ===

  /// Initialize rack product map
  ///
  /// [rackNameList] is initialized with [selectedModel?.products]
  /// [rackProductMap] is initialized with [selectedModel?.products]
  /// [rackNameList] is sorted
  ///
  /// [rackNameList] is reversed
  void initRackProductMap() {
    // step 1: clear rack name list and rack product map
    rackNameList.clear();
    rackProductMap.clear();

    // step 2: add rack name to rack name list & add product to rack product map
    selectedModel?.products.forEach((element) {
      if (!rackNameList.contains(element.rackName)) {
        rackNameList.add(element.rackName);
      }

      rackProductMap.putIfAbsent(element.rackName, () => []);
      rackProductMap[element.rackName]!.add(element);
    });

    // step 3: sort rack name list
    rackNameList.sort((a, b) => a.compareTo(b));
    rackNameList = rackNameList.reversed.toList();
  }

  /// Reset all variables of the provider
  void reset() {
    scannedList = [];
    isLoading = false;
    isError = false;
    errorMessage = "";
    scanMessage = "";
    rackNameList = [];
    rackProductMap = {};
  }

  /// Called from main_store home_screen store_detail
  ///
  /// It takes [LowStockModel] and navigate to [NavigationConstants.lowStockDetailRoute]
  ///
  /// [selectedModel] is set to [lowStockModel]
  /// [initRackProductMap] is called to show product according to rack
  /// [basketId] is set to empty string
  ///
  /// [box] is opened with [HiveDBService.openProductBox]
  /// [dao] is initialized with [ProductDao]
  ///
  /// [trolleyItems] is set to [dao.getAll()] to get all products that were added to trolley
  /// [updateLowStockModel] is called to update [LowStockModel] with trolley items
  /// [navigate] is called to navigate to [NavigationConstants.lowStockDetailRoute]
  ///
  /// [notifyListeners] is called
  void onDetailsTaped(
    BuildContext context,
    LowStockModel lowStockModel,
  ) async {
    // step 1: assign selected model, show product according to rack also clear basket id
    selectedModel = lowStockModel;
    initRackProductMap();
    basketId = "";

    // step 2: open box for low stock list
    box = await HiveDBService.openProductBox(
        '${HiveConstants.storeId}${lowStockModel.storeId}');
    dao = ProductDao(box);

    // step 3: get all products that were added to trolley & update low stock model
    if (context.mounted) {
      trolleyItems = dao.getAll();
      updateLowStockModel();
      navigate(context, route: NavigationConstants.lowStockDetailRoute);
      notifyListeners();
    }
  }

  /// ======== UTILITIES START ========
  
  /// to check if the product required quantity is scanned or not [LowStockDetailScreen]
  bool checkScanCount(int productId) {
    final prod = selectedModel?.products
        .firstWhere((element) => element.productId == productId);
    return prod?.scannedCount == prod?.quantity;
  }


  /// update [LowStockModel] with trolley items if found the status change to ItemStatus.done
  ///
  /// [selectedModel] is updated with [trolleyItems]
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

  /// check from the trolley items list for the specific product id
  ///
  /// return list of tags
  List<String> getScannedList(int productId) {
    return trolleyItems
        .where((element) => element.productId == productId)
        .expand((element) => element.tags)
        .toList();
  }

  /// called after carton scanned
  ///
  /// [model] is set to [selectedProduct]
  void onProductDetailsTaped(BuildContext context, ProductModel model) {
    trolleyItems = dao.getAll();
    scannedList = getScannedList(model.productId);
    selectedProduct = model;
    if (scannedList.isNotEmpty) {
      scanMessage =
          "Scan ${model.quantity - scannedList.length} ${model.productName} More";
    } else {
      scanMessage = "Scan ${model.quantity} ${model.productName} ";
    }
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, scanMessage);
    navigateReplacement(
      context,
      route: NavigationConstants.stockScannerRoute,
      extra: {"forProduct": true, "productId": model.productId},
    );
  }

  /// Open box for low stock list if there is product of store
  Future<List<LowStockModel>> openBoxForLowStockList(
      BuildContext context) async {
    List<LowStockModel> list = [];
    for (var element in lowStockList) {
      final box = await HiveDBService.openProductBox(
          '${HiveConstants.storeId}${element.storeId}');
      final dao = ProductDao(box);
      final trolleyItems = dao.getAll();
      if (trolleyItems.isNotEmpty) {
        list.add(element.copyWith(qty: trolleyItems.length));
      }
    }
    return list;
  }

  /// getMessageForTrolleyItem
  ///
  /// example message: Scan 10 Cadburys
  Future<void> getMessageForTrolleyItem(
      BuildContext context, int productId) async {
    scannedList.clear();
    final product =
        trolleyItems.firstWhere((element) => element.productId == productId);
    var message = "Scan ${product.quantity} ${product.productName}";
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }

  /// get tags of product in trolley whether scanned or not
  ///
  /// return list of tags
  List<String> getTagsOfProductInTrolley(int productId, bool remaining) {
    final product =
        trolleyItems.firstWhere((element) => element.productId == productId);
    if (remaining) {
      return product.tags
          .where((element) => !scannedList.contains(element))
          .toList();
    } else {
      return product.tags
          .where((element) => scannedList.contains(element))
          .toList();
    }
  }

  /// Display TAGS scanned or remaining
  void showTrolleyProductTags(BuildContext context, int productId) {
    final remainingTags = getTagsOfProductInTrolley(productId, true);
    final completedTags = getTagsOfProductInTrolley(productId, false);
    showProductTagSheet(context,
        remainingTags: remainingTags, completedTags: completedTags);
  }

  /// ======== UTILITIES END ========

  /// ================ CODE DETECTION FOR LOW STOCK START ====================

  /// [lowStockCartonScan] is called from low_stock_details screen Scan Button
  ///
  /// [code] comes from stock_scanner screen
  Future<ScanResult> lowStockCartonScan(
      BuildContext context, String code) async {
    try {
      await callCartonInfoApi(context, code);
      if (cartonModel == null) {
        return ScanResult(success: false, message: "No matching carton found");
      }

      final matchedModel = selectedModel?.products.firstWhereOrNull(
          (element) => element.productId == cartonModel!.productId);

      if (matchedModel == null) {
        return ScanResult(success: false, message: "No matching product found");
      }

      if (checkScanCount(matchedModel.productId)) {
        return ScanResult(success: false, message: "Already scanned");
      }
      if (context.mounted) {
        onProductDetailsTaped(context, matchedModel);
      }
      return ScanResult(
          success: true,
          message: "Carton Scanned : ${cartonModel!.productName}");
    } catch (e) {
      return ScanResult(success: false, message: e.toString());
    }
  }

  /// [checkItemQr] is called from stock_scanner screen
  ///
  /// [code] comes from stock_scanner screen
  /// It is used to scan product tags while adding products in trolley
  Future<ScanResult> checkItemQr(BuildContext context, String code) async {
    try {
      // step 1: check if scannedList contains code
      if (scannedList.contains(code)) {
        return ScanResult(success: false, message: "Tag Already scanned");
      }
      // step 2: scanned list has only selected product tags
      if (selectedProduct?.quantity == scannedList.length) {
        return ScanResult(success: false, message: "Product already scanned");
      }

      // step 3: add code to scannedList
      scannedList.add(code);
      // step 4: add or update product in trolley [local database]
      await dao.addOrUpdateProduct(TrolleyItem(
        productId: selectedProduct!.productId,
        productName: selectedProduct!.productName,
        image: selectedProduct!.imageUrl,
        tags: scannedList,
        quantity: scannedList.length,
      ));
      // step 5: get all products that were added to trolley [local database]
      trolleyItems = dao.getAll();

      // step 6: update scan message
      final scannedCount = scannedList.length;

      // step 7: update scan message
      scanMessage =
          "Scan ${(selectedProduct?.quantity ?? 0) - (scannedCount)} ${selectedProduct?.productName} More";
      if (context.mounted) {
        Provider.of<ScanMessageProvider>(context, listen: false)
            .setMessage(context, scanMessage);
      }

      // step 8: check if all tags are scanned; if yes then clear scannedList and notify listeners
      if (scannedList.length == selectedProduct?.quantity) {
        scannedList = [];
        notifyListeners();
        return ScanResult(success: true, message: "Scanned Successfully");
      }

      // if return false means required number of tags are not scanned
      notifyListeners();
      return ScanResult(success: false);
    } catch (e) {
      // if exception occurs return false with error message
      return ScanResult(success: false, message: e.toString());
    }
  }

  /// ================ CODE DETECTION FOR LOW STOCK END ====================

  /// ================ CODE DETECTION FOR COLLECTED PRODUCT VIEW START ====================
  
  /// [checkBasketQr] is called from collected_product_view screen [onTapDetails]
  /// 
  /// [code] comes from collected_product_view screen
  Future<ScanResult> checkBasketQr(BuildContext context, String code) async {
    scanMessage = "";
    notifyListeners();

    try {
      // step 1: check if code contains basket
      if (!code.contains("basket")){
        return ScanResult(success: false, message: "Please scan basket code");
      }
      // step 2: call api to update scanned tags
      final value = await postBasketCode(context, code);
      // step 3: if api call is successful; return true with success message also update basketId
      if (value) {
        basketId = code;
        return ScanResult(success: true, message: "Basket Scanned Successfully");
      } 
      // step 4: if api call is not successful; return false with error message
      else {
        return ScanResult(success: false, message: "Basket Scanned Failed");
      }
    } catch (e) {
      // if exception occurs; return false with error message
      return ScanResult(success: false, message: e.toString());
    }
  }

  /// FOR TROLLEY Items
  ///
  /// on scan trolley items
  Future<ScanResult> onScanTrolleyItems(
      BuildContext context, int productId, String code) async {
    try {
      // check if scannedList contains code
      // split code and check first part is productId

      // step 1: check if productId matches
      if (code.split("-").first != productId.toString()) {
        return ScanResult(
            success: false, message: "Invalid QR - Product ID does not match");
      }
      // step 2: check if scannedList contains code
      if (scannedList.contains(code)) {
        return ScanResult(success: false, message: "Tag Already scanned");
      }
      // step 3: get item from trolleyItems; to check whether item exist or not [local database]
      final item = trolleyItems
          .firstWhereOrNull((element) => element.productId == productId);
      if (item == null) {
        return ScanResult(success: false, message: "Product not found");
      }
      // step 4: check if tag is already scanned
      if (!item.tags.contains(code)) {
        return ScanResult(
            success: false, message: "Product not found in trolley");
      }
      // step 5: add code to scannedList
      scannedList.add(code);
      // step 6: check if all tags are scanned
      if (scannedList.length == item.quantity) {
        // if true; call api to update scanned tags
        final result = await postTrolleyScannedTags(context, productId);
        // if api call is successful; clear scannedList & update trolleyItems & notify listeners
        scannedList = [];
        if (result) {
          trolleyItems = dao.getAll();
          notifyListeners();
          return ScanResult(success: true, message: "Scanned Successfully");
        } 
        // if api call is not successful; return false with error message
        else {
          return ScanResult(
              success: false,
              message: "Something went wrong, Please try again");
        }
      }
      // if all tags are not scanned; update scan message
      Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
          context,
          "Scan ${item.quantity - scannedList.length} ${item.productName} More");
      notifyListeners();
      // if all tags are not scanned; return false; it means no message to display keep scanning more tags
      return ScanResult(success: false);
    } catch (e) {
      // if exception occurs; return false with error message
      return ScanResult(success: false, message: e.toString());
    }
  }

  /// ================== API CALLS START ==================
  ///

  /// It is used to check whether the basket code is valid or not
  ///
  /// If valid then it will open the store model and show the products [TrolleyItemScreen]
  ///
  /// [code] comes from stock_scanner screen
  Future<bool> postBasketCode(BuildContext context, String code) async {
    // step 1: clear scanned list
    scannedList = [];
    try {
      // step 2: show loading
      showLoading(context);
      
      // step 3: call api
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.scanBasketUrl,
        body: {
          "basket_identifier": code,
        },
      );
      debugPrint("Basket Code: ${response.data}");
      
      // step 4: check response; if not 200 then throw exception
      if (response.statusCode != 200) {
        throw "Failed to scan basket";
      }
      
      // step 5: get store id
      int storeId = response.data['store_id'].toString().toInt();
      
      // step 6: get trolley low stock model
      trolleyLowStockModel =
          lowStockList.firstWhereOrNull((element) => element.storeId == storeId);
      if (trolleyLowStockModel == null) {
        throw "Store not found for low stock";
      }
      
      // step 7: remove loading
      if (context.mounted) {
        removeLoading(context);
      }
      
      // step 8: open product box
      box = await HiveDBService.openProductBox(
          '${HiveConstants.storeId}$storeId');
      dao = ProductDao(box);
      trolleyItems = dao.getAll();
      
      // step 9: return true; if everything is fine
      return true;
    } catch (e) {
      // on error: remove loading & rethrow
      if (context.mounted) {
        removeLoading(context);
      }
      rethrow;
    }
  }

  // After scanning trolley product tags 
  Future<bool> postTrolleyScannedTags(
      BuildContext context, int productId) async {
    try {
      // step 1: show loading
      showLoading(context);
      
      // step 2: call api
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.addProductsUrl,
        body: {
          "store_id": trolleyLowStockModel?.storeId,
          "product_units": scannedList,
          "basket_identifier": basketId,
        },
      );
      
      // step 3: remove loading
      if (context.mounted) {
        removeLoading(context);
      }
      
      // step 4: check response
      if (response.statusCode != 200 && response.statusCode != 201) {
        scannedList.clear();
        if (context.mounted) {
          getMessageForTrolleyItem(context, productId);
        }
        throw "Something went wrong, while posting scanned tags";
      }
      
      // step 5: delete product from local database
      dao.deleteProduct(productId.toString());
      
      // step 6: remove product from selected model
      selectedModel?.products
          .removeWhere((element) => element.productId == productId);
      
      // step 7: init rack product map
      initRackProductMap();
      
      // step 8: return true
      return true;
    } catch (e) {
      // on error: remove loading & show message
      if (context.mounted) {
        removeLoading(context);
        getMessageForTrolleyItem(context, productId);
      }
      scannedList.clear();
      rethrow;
    }
  }

  /// get low stock store with products on dashboard for main_store
  Future<void> fetchLowStockProducts(BuildContext context,
      {bool isFromBuild = false}) async {
    try {
      // step 1: reset variables
      isLoading = true;
      isError = false;
      errorMessage = "";

      // step 2: cancel notification schedule
      FirebaseAPI().cancelScheduledNotification();

      // step 3: notify listeners if not from build
      if (context.mounted && !isFromBuild) {
        notifyListeners();
      }
      
      // step 4: fetch low stock products
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.lowStockUrl,
      );

      // step 5: update low stock list; else set error
      if (response.statusCode == 200) {
        lowStockList = [];
        for (var item in response.data) {
          lowStockList.add(LowStockModel.fromJson(item));
        }
      } else {
        isError = true;
        errorMessage = "No data found";
      }
      
      // step 6: schedule notification
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
      // step 1: reset carton model & show loading
      cartonModel = null;
      showLoading(context);

      // step 2: check if code is carton code
      if (!code.contains("carton")) {
        throw "Invalid Carton QR";
      }

      // step 3: call api
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.cartonInfoUrl.replaceAll(':id', code),
      );
      debugPrint("Carton Info response code: ${response.statusCode}");

      // step 4: update carton model & remove loading
      if (context.mounted) {
        removeLoading(context);
      }
      if (response.statusCode == 200) {
        cartonModel = CartonModel.fromJson(response.data, code);
      }
    } catch (e) {
      // on error: remove loading & rethrow
      if (context.mounted) {
        removeLoading(context);
      }
      rethrow;
    }
  }
}
