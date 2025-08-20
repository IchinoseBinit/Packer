import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/extensions/list_extension.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/hive_db/basket_dao.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/router.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/auth/model/order_notification.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/order/models/order_completed_details.dart';
import 'package:packer/features/views/order/models/order_picked_details.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/order/models/unsettled_orders.dart';
import 'package:packer/features/views/scanner/model/scan_result.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/summary/models/daily_summary.dart';
import 'package:packer/features/views/summary/models/weekly_summary.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/post_basket_model.dart';
import 'package:provider/provider.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderNotification> orders = <OrderNotification>[];
  OrderDetailModel? _orderDetails; // Change to OrderDetailsFetch type
  OrderPickedDetails? orderPickedDetails;
  CompletedOrderDetails? completedOrderDetails;
  WeeklySummary? weeklySummary;
  bool _isAvailable = false;
  int packedCount = 0;
  final Set<int> _alreadyIncremented = {};

  DailySummary? dailySummary;
  String? _error;
  OrderDetailModel? get orderDetails => _orderDetails; // Change getter type
  String? get error => _error;
  var isLoading = false;
  UnsettledOrders? unsettledOrders;
  List<OrderNotification> latestOrder = [];
  bool hasScanned = false;
  List<String> damagedProductTags = [];

  set isAvailable(val) {
    _isAvailable = val;
  }

  List<String> rackList = [];
  Map<String, List<ProductDetails>> rackProductData = {};

  late Box<Basket> basketBox;
  late BasketDao basketDao;

  List<Basket> baskets = [];
  // List<String> basketDataList = []; // stores basket codes
  // Map<String, List<String>> scannedDataPerBasket =
  //     {}; // map product tag with basket code
  List<String> scannedDataList =
      []; // stores all scanned product tags for all baskets

  get isAvailable => _isAvailable;

  List<String> get basketDataList => baskets.map((e) => e.identifier).toList();

  // current basket code
  String bucketData = "";
  String damageProductId = '';

  set bucket(String value) {
    final basket = basketDao.getBasket(value);
    if (basket != null) {
      bucketData = value;
    } else {
      basketDao
          .addOrUpdateBasket(Basket(identifier: value, productIdentifiers: []));
      baskets = basketDao.getAll();
      bucketData = value;
    }
    notifyListeners();
  }

  void addProductTagToBasket(String basketId, String productTag) {
    // if (!scannedDataPerBasket.containsKey(basketId)) {
    //   scannedDataPerBasket[basketId] = [];
    // }
    // scannedDataPerBasket[basketId]!.add(productTag);
    final basket = basketDao.getBasket(basketId);
    if (basket != null) {
      basket.productIdentifiers.add(productTag);
      basketDao.addOrUpdateBasket(basket);
    } else {
      basketDao.addOrUpdateBasket(
          Basket(identifier: basketId, productIdentifiers: [productTag]));
    }
    baskets = basketDao.getAll();
  }

  bool allCartItemScanned() {
    for (ProductDetails element in _orderDetails?.productDetails ?? []) {
      if (element.quantity != countScannedItem(element.id)) {
        return false;
      }
    }
    return true;
  }

  var hasUploadedHomeImage = false;

  resetUploadedHomeImage() {
    hasUploadedHomeImage = false;
    notifyListeners();
  }

  void acceptOrder(int index) {
    orders.removeAt(index);
    notifyListeners();
  }

  void initState() {
    resetPackedTracking();
    packedCount = 0;
    scannedDataList.clear();
    scannedDataList =
        baskets.map((e) => e.productIdentifiers).expand((x) => x).toList();

    // check number of product scanned with required quantity for productCount
    for (var element in _orderDetails?.productDetails ?? <ProductDetails>[]) {
      if (element.quantity == countScannedItem(element.id)) {
        incrementPackedOnce(element.id);
      }
    }

    // remainingquantity = orderDetails?.productDetails[0].quantity ?? 0;
  }

  // UPDATED
  void resetState() {
    basketDataList.clear();
    baskets.clear();
    scannedDataList.clear();
    rackProductData.clear();
    rackList.clear();
  }

  // check by item id in scan list with required quantity
  bool checkItem(int productId) {
    for (ProductDetails element in _orderDetails?.productDetails ?? []) {
      if (element.id == productId) {
        // get from scanned data list split by -
        final scannedLength = scannedDataList
            .where((item) => item.startsWith(productId.toString()))
            .length;
        if (scannedLength == element.quantity) {
          return true;
        }
      }
    }
    return false;
  }

  // UPDATED // accept or detail of order
  void onOrderAcceptOrGetDetail(int orderId,
      {bool fromCall = false, BuildContext? context}) async {
    // open box
    basketBox = await Hive.openBox('${HiveConstants.order}$orderId');
    basketDao = BasketDao(basketBox);
    baskets = basketDao.getAll();
    if (baskets.isNotEmpty && !fromCall) {
      bucket = baskets.first.identifier;
      initState();
      navigate(context!,
          route: NavigationConstants.orderDetailsRoute, extra: orderId);
    } else {
      if (fromCall) {
        navigateWithRouter(
          AppRouter.router,
          route: NavigationConstants.basketScanScreenRoute,
          extra: {
            'forOrder': true,
            'fromCall': true,
            'orderId': orderId,
          },
        );
      } else {
        await navigate(context!,
            route: NavigationConstants.basketScanScreenRoute,
            extra: {
              'forOrder': true,
              'fromCall': true,
              'orderId': orderId,
            });
        // log("result from basket scan screen $result", name: "Order Detials");
        // if (result ?? false) {
        //   initState();
        //   navigate(context,
        //       route: NavigationConstants.orderDetailsRoute, extra: orderId);
        // }
      }
    }
    // scan basket
    notifyListeners();
  }

  // UPDATED
  int countScannedItem(int productId) {
    final scannedLength = scannedDataList
        .where((item) => item.startsWith(productId.toString()))
        .length;
    return scannedLength;
  }

  // UPDATED
  String scanProductMessage(int productId) {
    log("Message Product Id: $productId");
    for (var element in _orderDetails?.productDetails ?? []) {
      if (element.id == productId) {
        return "Scan ${element.quantity - countScannedItem(productId)} ${element.productName}";
      }
    }
    return "";
  }

  // UPDATED
  ScanResult scanProduct(BuildContext context, int cartItemId, String code) {
    for (var element in _orderDetails?.productDetails ?? []) {
      if (element.id == cartItemId) {
        if (scannedDataList.contains(code)) {
          return ScanResult(
              success: false, message: "QR: $code already scanned");
        }
        updateProductList(code);
        if (countScannedItem(cartItemId) == element.quantity) {
          //aaaaa
          incrementPackedOnce(element.id);

          notifyListeners();
          return ScanResult(success: true, message: "Scanned Successfully");
        } else {
          final scanMessage =
              "Scan ${(element.quantity ?? 0) - countScannedItem(cartItemId)} more ${element.productName}";
          Provider.of<ScanMessageProvider>(context, listen: false)
              .setMessage(context, scanMessage);
          return ScanResult(success: false);
        }
      }
    }
    return ScanResult(success: false, message: "Product not found");
  }

  /// Use order type to pass multiple values
  Future<void> fetchOrders(
      {OrderStatusType orderStatus = OrderStatusType.created,
      String? orderType}) async {
    try {
      isLoading = true;
      Future.delayed(Duration.zero, () {
        notifyListeners();
      });

      var url = AppUrls.getOrdersByStatusUrl;
      url += orderType ?? orderStatus.toString();
      final date = DateFormat("yyyy-MM-dd").format(DateTime.now());
      url += "&date=$date";

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );

      final List<dynamic> data = response.data;
      orders = data.map((order) => OrderNotification.fromJson(order)).toList();
      isLoading = false;
      notifyListeners();
    } catch (ex) {
      print('Error: $ex');
      throw Exception('Failed to load carts: $ex');
    }
  }

  clearLatestOrder({bool isFromPayment = true}) {
    latestOrder.clear();
    if (isFromPayment) {
      isAvailable = false;
    }
    notifyListeners();
  }

  Future<void> fetchLatestOrders({bool isFirstTime = false}) async {
    try {
      if (!isFirstTime) {
        clearLatestOrder(isFromPayment: false);
        isLoading = true;
        notifyListeners();
      }
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.getLatestOrdersUrl,
      );

      final List<dynamic> data = response.data;
      latestOrder =
          data.map((order) => OrderNotification.fromJson(order)).toList();
      isLoading = false;

      notifyListeners();
    } catch (ex) {
      print('Error: $ex');
      isLoading = false;
      notifyListeners();
      throw Exception('Failed to load carts: $ex');
    }
  }

  void mapProductToRack() {
    rackList.clear();
    rackProductData.clear();
    for (var element in _orderDetails?.productDetails ?? []) {
      if (!rackList.contains(element.rackName)) {
        rackList.add(element.rackName);
      }
      if (rackProductData.containsKey(element.rackName)) {
        rackProductData[element.rackName]!.add(element);
      } else {
        rackProductData[element.rackName] = [element];
      }
    }

    // sort
    rackList.sort((a, b) => a.compareTo(b));
    notifyListeners();
  }

  Future<void> acknowledgeOrder(BuildContext context, String orderId) async {
    try {
      // debugger();
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: "${AppUrls.acknowledgeOrderUrl}/$orderId/acknowledge-packer/",
      );

      if (response.statusCode == 200) {
        _orderDetails = OrderDetailModel.fromJson(response.data);
        mapProductToRack();

        final notifications =
            Provider.of<HomeProvider>(context, listen: false).notifications;

        //Show snackbar
        final index =
            notifications.indexWhere((element) => element.orderId == orderId);
        // final orderItem = notifications[index];
        if (index >= 0) {
          notifications.removeAt(index);
        }
        initState();

        fetchLatestOrders();
        notifyListeners();
      } else {
        print('Error acknowledging order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error acknowledging order: $e');
      // rethrow;
    }
  }

  Future<Map<String, bool>> productPost(BuildContext context, int orderId) async {
    // List<Basket> baskets = basketDataList.map((identifier) {
    //   return Basket(
    //     identifier: identifier,
    //     productIdentifiers:
    //         List<String>.from(scannedDataPerBasket[identifier] ?? []),
    //   );
    // }).toList();

    PostBasketRequest postBasketRequest = PostBasketRequest(
      orderId: orderId,
      data: baskets,
    );

    try {
      log(postBasketRequest.toJson().toString(), name: "productPost body data");

      print("${postBasketRequest.toJson()}productPost body data");

      showLoading(context);

      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.productPostDetail,
        body: postBasketRequest.toJson(),
      );

      removeLoading(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("Successfully posted basket data", name: "basket data response");
        clearBasket(baskets.first.identifier);
        resetState();
        // remove box
        basketDataList.clear();
        basketDao.clearAll();
        scannedDataList.clear();
        
        notifyListeners();
        return {
          "success": true,
          "isCancelRequest": response.data['is_cancel_request'].toString().toBool(false),
        };
      } else {
        ErrorHandler.alertDialog(context, "Failed to post basket data");
        log('Error posting basket data: ${response.statusCode}',
            name: "basket data response");
        return {
          "success": false,
          "isCancelRequest": false,
        };
      }
    } catch (e) {
      removeLoading(context);
      log('Error posting basket data: $e', name: "basket data response");
      ErrorHandler.alertDialog(context, e.toString());
      notifyListeners();
      return {
        "success": false,
        "isCancelRequest": false,
      };
    }
  }

  Future fetchUnsettledOrders() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.getUnsettledOrdersUrl,
      );

      if (response.statusCode == 200) {
        unsettledOrders = UnsettledOrders.fromJson(response.data);
        notifyListeners();
      } else {
        throw response.data;
      }
    } catch (e) {
      unsettledOrders = null;
      notifyListeners();

      return e;
    }
  }

  Future createSettlementRequest() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.createSettlementRequestUrl,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(response.data);
        throw response.data;
      }
    } catch (e) {
      return e;
    }
  }

  Future fetchOrderSummary({String? startDate, String? endDate}) async {
    try {
      var url = AppUrls.orderSummaryUrl;
      if (endDate != null) {
        url += "$startDate/$endDate/";
      }
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );

      if (response.statusCode == 200) {
        weeklySummary = WeeklySummary.fromJson(response.data);
        notifyListeners();
        return true;
      } else {
        throw response.data;
      }
    } catch (e) {
      return e;
    }
  }

  Future fetchDailySummary({required String startDate, String? endDate}) async {
    try {
      var url = "${AppUrls.dailySummaryUrl}$startDate/";
      if (endDate != null) {
        url += "$endDate/";
      }
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );

      if (response.statusCode == 200) {
        dailySummary = DailySummary.fromJson(response.data);
        notifyListeners();
        return true;
      } else {
        throw response.data;
      }
    } catch (e) {
      return e;
    }
  }

  // UPDATED
  updateProductList(String? data) async {
    if (data != null) {
      addProductTagToBasket(bucketData, data);
      scannedDataList.add(data);
      notifyListeners();
      log("Updated scanned data list $scannedDataList",
          name: "scanned data list");
    }
  }

  // UPDATED and flow fixed
  Future<ScanResult> updateBucketData(
      BuildContext context, String? data) async {
    if (data != null) {
      log("Basket code scanned from order acknowledge $data");

      final result = await clearBasket(data);
      if (!result.success) {
        return result;
      }
      bucket = data;
      log("basket code list $basketDataList");
      notifyListeners();
      return ScanResult(success: true);
    }
    return ScanResult(success: false, message: "Failed to update bucket data");
  }

  // UPDATED and flow fixed
  Future<ScanResult> clearBasket(String code) async {
    try {
      var url = AppUrls.basketClearUrl;
      final response = await DioClient()
          .request(requestType: RequestType.postWithToken, url: url, body: {
        "basket_id": code,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ScanResult(success: true);
      }
      return ScanResult(success: false, message: "Failed to clear basket");
    } catch (e) {
      return ScanResult(success: false, message: e.toString());
    }
  }

  Future uploadImages(
    List<File> files,
    BuildContext context,
    String productId,
  ) async {
    try {
      var formData = FormData();

      // Add product_id field
      formData.fields.add(MapEntry("product_id", productId));

      // Add each image file
      for (int i = 0; i < files.length; i++) {
        formData.files.add(
          MapEntry(
            "images", // Change to "images" if API doesn't expect []
            await MultipartFile.fromFile(files[i].path),
          ),
        );
      }
      final response = await DioClient().request(
        requestType: RequestType.postWithTokenFormData,
        url: AppUrls.damageProductImageUpload,
        body: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        removeLoading(context);
        damagedProductTags = List<String>.from(response.data['tags'] ?? []);
        hasUploadedHomeImage = true;

        notifyListeners();
        return true;
      } else {
        hasUploadedHomeImage = false;
        throw response.data;
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      hasUploadedHomeImage = false;
      return e;
    }
  }

  final List<String> scannedDamageProductList = [];

  scanDamagedProductBasket(String code) {
    bucketData = "";

    if (code.isEmpty) {
      return;
    } else {
      bucketData = code;
      notifyListeners();
    }
  }

  scannedDamageProduct(String code) {
    if (code.isEmpty) {
      return;
    } else {
      if (scannedDamageProductList.contains(code)) {
        showToast("Product already scanned");
        return false;
      }
      scannedDamageProductList.add(code);
      notifyListeners();
      return true;
    }
  }

  void damageProductTransfer(BuildContext context) async {
    final Map<String, dynamic> body = {
      "identifier": bucketData,
      "product_tags": scannedDamageProductList,
    };

    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.damagedProductTransfer,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        scannedDamageProductList.clear();
        bucketData = "";
        navigateReplacement(context, route: NavigationConstants.dashboardRoute);
        notifyListeners();
      } else {
        // Handle server error gracefully
        showToast(response.data['error'] ?? "Failed to transfer products");
      }
    } catch (e) {
      showToast("Error: $e");
    }
  }

  

  void incrementPackedOnce(int productId) {
    if (_alreadyIncremented.contains(productId)) return;

    _alreadyIncremented.add(productId);
    packedCount++;
    notifyListeners();
  }

  void resetPackedTracking() {
    _alreadyIncremented.clear();
  }

  
}
