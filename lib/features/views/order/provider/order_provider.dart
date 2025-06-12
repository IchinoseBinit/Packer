import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';

import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/auth/model/order_notification.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/order/models/order_completed_details.dart';
import 'package:packer/features/views/order/models/order_picked_details.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/order/models/unsettled_orders.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/summary/models/daily_summary.dart';
import 'package:packer/features/views/summary/models/weekly_summary.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/post_basket_model.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderNotification> orders = <OrderNotification>[];
  OrderDetailModel? _orderDetails; // Change to OrderDetailsFetch type
  OrderPickedDetails? orderPickedDetails;
  CompletedOrderDetails? completedOrderDetails;
  WeeklySummary? weeklySummary;
  bool _isAvailable = false;

  DailySummary? dailySummary;
  String? _error;
  OrderDetailModel? get orderDetails => _orderDetails; // Change getter type
  String? get error => _error;
  var isLoading = false;
  UnsettledOrders? unsettledOrders;
  List<OrderNotification> latestOrder = [];
  bool hasScanned = false;

  set isAvailable(val) {
    _isAvailable = val;
  }

  List<String> rackList = [];
  Map<String, List<ProductDetails>> rackProductData = {};

  String bucketData = ""; // current basket code
  List<String> basketDataList = []; // stores basket codes
  Map<String, List<String>> scannedDataPerBasket =
      {}; // map product tag with basket code
  List<String> scannedDataList =
      []; // stores all scanned product tags for all baskets

  get isAvailable => _isAvailable;

  void addProductTagToBasket(String basketId, String productTag) {
    if (!scannedDataPerBasket.containsKey(basketId)) {
      scannedDataPerBasket[basketId] = [];
    }
    scannedDataPerBasket[basketId]!.add(productTag);
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
    scannedDataList.clear();
    // remainingquantity = orderDetails?.productDetails[0].quantity ?? 0;
  }

  // UPDATED
  void resetState() {
    basketDataList.clear();
    scannedDataPerBasket.clear();
    scannedDataList.clear();
    rackProductData.clear();  
    rackList.clear();
  }

  // check by item id in scan list with required quantity
  bool checkItem(int productId) {
    // debugger();
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
        return "Scan ${element.quantity - element.itemScanCount} ${element.productName}";
      }
    }
    return "";
  }

  // UPDATED
  bool scanProduct(BuildContext context, int cartItemId, String code) {
    for (var element in _orderDetails?.productDetails ?? []) {
      if (element.id == cartItemId) {
        if (scannedDataList.contains(code)) {
          ErrorHandler.alertDialog(context, "QR: $code already scanned");
          return false;
        }
        updateProductList(code);
        if (countScannedItem(cartItemId) == element.quantity) {
          showToast("Item scanned successfully");
          notifyListeners();
          return true;
        } else {
          final scanMessage =
              "Scan ${(element.quantity ?? 0) - countScannedItem(cartItemId)} more ${element.productName}";
          Provider.of<ScanMessageProvider>(context, listen: false)
              .setMessage(context, scanMessage);
          return false;
        }
      }
    }
    return false;
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

  Future<bool> productPost(BuildContext context, int orderId , String otp) async {
    List<Basket> baskets = basketDataList.map((identifier) {
      return Basket(
        identifier: identifier,
        productIdentifiers:
            List<String>.from(scannedDataPerBasket[identifier] ?? []),
      );
    }).toList();

    PostBasketRequest postBasketRequest = PostBasketRequest(
      orderId: orderId,
      data: baskets,
      otp: otp,
    );

    try {
      log(postBasketRequest.toJson().toString(), name: "productPost body data");

      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.productPostDetail,
        body: postBasketRequest.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("Successfully posted basket data", name: "basket data response");
        resetState();
        notifyListeners();
        return true;
      } else {
        ErrorHandler.alertDialog(context, "Failed to post basket data");
        log('Error posting basket data: ${response.statusCode}',
            name: "basket data response");
        return false;
      }
    } catch (e) {
      log('Error posting basket data: $e', name: "basket data response");
      ErrorHandler.alertDialog(context, e.toString());
      notifyListeners();
      return false;
    }
  }

 

  Future fetchUnsettledOrders() async {
    try {
      debugger();
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
  Future<bool> updateBucketData(BuildContext context, String? data) async {
    if (data != null) {
      log("Basket code scanned from order acknowledge $data");

      bucketData = data;

      if (basketDataList.contains(data)) {
        ErrorHandler.alertDialog(context, "Basket Already Scanned");
        return false;
      }

      // not mandatory just to clear previous basket data
      await clearBasket();

      basketDataList.add(data);
      log("basket code list $basketDataList");
      notifyListeners();
      return true;
    }
    return false;
  }

  // UPDATED and flow fixed
  Future<bool> clearBasket() async {
    try {
      var url = AppUrls.basketClearUrl;
      final response = await DioClient()
          .request(requestType: RequestType.postWithToken, url: url, body: {
        "basket_id": bucketData,
      });
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  
}
