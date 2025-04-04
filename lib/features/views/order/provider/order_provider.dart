import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';

import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/auth/model/order_notification.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/order/models/order_completed_details.dart';
import 'package:packer/features/views/order/models/order_picked_details.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/order/models/unsettled_orders.dart';
import 'package:packer/features/views/summary/models/daily_summary.dart';
import 'package:packer/features/views/summary/models/weekly_summary.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
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
  String? scanMessage;
  UnsettledOrders? unsettledOrders;
  List<OrderNotification> latestOrder = [];

  set isAvailable(val) {
    _isAvailable = val;
  }

  String bucketData = "";
  List<String> scannedDataList = [];

  get isAvailable => _isAvailable;
  bool showButton = false;

  // List<SeeOrderDetailsPacker> parseOrderItems(List<dynamic> orderItemsJson) {
  //   return orderItemsJson
  //       .map((json) => SeeOrderDetailsPacker.fromJson(json))
  //       .toList();
  // }

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
  }

  void initScanMessage(int productId) {
    if (kDebugMode) {
      showToast('Item Id: $productId');
    }
    for (var element in _orderDetails?.productDetails ?? []) {
      if (element.id == productId) {
        scanMessage =
            "Scan ${element.quantity - element.itemScanCount} ${element.productName}";
        notifyListeners();
        return;
      }
    }
  }

  checkItemQr(
    BuildContext context,
    MobileScannerController? controller,
    String code,
  ) {
    controller?.stop();

    log(code, name: "qr code data");

    HapticFeedback.heavyImpact();

    showLoading(context);

    if (code.contains('-')) {
      final prodId = int.tryParse(code.split('-').first) ?? 0;

      try {
        final isScanned = scanCountOrder(prodId);

        updateProductList(code);
        if (isScanned) {
          removeLoading(context);
          Navigator.pop(context);
        } else {
          removeLoading(context);
          controller?.start();
        }
        // onBackPressed();
        // showToast("joined the waiting list");
      } catch (ex) {
        removeLoading(context);
        showToast(ex.toString());
        print(ex.toString());
      }
    } else {
      removeLoading(context);
      ShowAlertDialog(
        body: const Text("Invalid QR"),
        okFunc: () {
          Navigator.pop(context);
          controller?.start();
        },
      ).showAlertDialog(context);
      controller?.start();
    }
  }

  bool scanCountOrder(int cartItemId) {
    for (var element in _orderDetails?.productDetails ?? []) {
      print("ssssssssssss: ${element.id}");

      if (element.id == cartItemId) {
        if (element.itemScanCount == element.quantity) {
          showToast("Item already scanned");
          return false;
        }
        element.itemScanCount++;
        if (element.itemScanCount == element.quantity) {
          scanMessage = null;
          showToast("Item scanned successfully");

           showButton = true;

          notifyListeners();
          return true;
        } else {
          scanMessage =
              "Scan ${element.quantity - element.itemScanCount} more ${element.productName}";
        }
        notifyListeners();
        return false;
      }
    }
    showToast("Item not found");
    notifyListeners();
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

  Future<void> acknowledgeOrder(BuildContext context, String orderId) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: "${AppUrls.acknowledgeOrderUrl}/$orderId/acknowledge-packer/",
      );

      if (response.statusCode == 200) {
        _orderDetails = OrderDetailModel.fromJson(response.data);

        final notifications =
            Provider.of<HomeProvider>(context, listen: false).notifications;

        //Show snackbar
        final index =
            notifications.indexWhere((element) => element.orderId == orderId);
        // final orderItem = notifications[index];
        if (index >= 0) {
          notifications.removeAt(index);
        }
        // navigate(context,
        //     route: NavigationConstants.bucketqrScreenRoute, extra: orderId);

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

  Future<bool> productPost(
    int orderId,
  ) async {
    try {
      log(scannedDataList.toString(), name: "product scan response");
      final response = await DioClient().request(
          requestType: RequestType.postWithToken,
          url: AppUrls.productPostDetail,
          body: {
            "order_id": orderId,
            "identifier": bucketData,
            "product_unit_tags": scannedDataList
          });

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        print('Error getting order details: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error getting order details: $e');
      _error = 'Failed to load order details: $e';
      notifyListeners();
      return false;
    }
  }

  Future getBilledOrder(String orderId) async {
    orderPickedDetails = null;
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.billOrderUrl.replaceFirst("id", orderId),
      );

      if (response.statusCode == 200) {
        orderPickedDetails = OrderPickedDetails.fromJson(response.data);
        hasUploadedHomeImage = false;
        notifyListeners();
        print(
            "__________________________________________________________________________________");
        print(orderPickedDetails);
        return true;
      } else {
        throw response.data;
      }
    } catch (ex) {
      orderPickedDetails = null;
      return ex;
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

  void addList(String data) {
    scannedDataList.add(data);

    print(scannedDataList);

    notifyListeners();
  }

  updateProductList(String? data) async {
    if (data != null) {
      if (scannedDataList.contains(data)) {
        showToast("Product Already Scanned");
      } else {
        return addList(data);
      }
    }
  }

  updateBucketData(String? data) async {
    if (data != null) {
      bucketData = data;
      log(bucketData, name: "basket data:::::::::::");
    }
  }
}
