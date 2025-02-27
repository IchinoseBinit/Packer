import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:galli_map/galli_map.dart';
import 'package:intl/intl.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/auth/model/order_notification.dart';
import 'package:packer/features/views/order/models/fetch_order_details.dart';
import 'package:packer/features/views/order/models/order_completed_details.dart';
import 'package:packer/features/views/order/models/order_picked_details.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/order/models/unsettled_orders.dart';
import 'package:packer/features/views/summary/models/daily_summary.dart';
import 'package:packer/features/views/summary/models/weekly_summary.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderNotification> orders = <OrderNotification>[];
  OrderDetailsFetch? _orderDetails; // Change to OrderDetailsFetch type
  OrderPickedDetails? orderPickedDetails;
  CompletedOrderDetails? completedOrderDetails;
  WeeklySummary? weeklySummary;
  DailySummary? dailySummary;
  String? _error;
  late Position _currentPosition;
  LatLng destinationLocation = LatLng(27.673, 85.328);
  OrderDetailsFetch? get orderDetails => _orderDetails; // Change getter type
  String? get error => _error;
  var isLoading = false;
  UnsettledOrders? unsettledOrders;
  List<SeeOrderDetailsPacker> parseOrderItems(List<dynamic> orderItemsJson) {
    return orderItemsJson
        .map((json) => SeeOrderDetailsPacker.fromJson(json))
        .toList();
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

  Future<void> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    _currentPosition = position;
    notifyListeners();
  }

  Position get currentPosition => _currentPosition;

  void updateDestination(LatLng newDestination) {
    destinationLocation = newDestination;
    notifyListeners();
  }

  setInitialLocation(Position currentPosition) {
    _currentPosition = currentPosition;
    notifyListeners();
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

  Future<void> fetchOrderDetails(String orderId) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.orderDetailsUrl.replaceFirst("id", orderId),
      );

      if (response.statusCode == 200) {
        _orderDetails = OrderDetailsFetch.fromJson(response.data);
        notifyListeners();
      } else {
        print('Error getting order details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting order details: $e');
      _error = 'Failed to load order details: $e';
      notifyListeners();
    }
  }

  Future billOrder(String orderId) async {
    orderPickedDetails = null;
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.billOrderUrl.replaceFirst("id", orderId),
      );

      if (response.statusCode == 200) {
        orderPickedDetails = OrderPickedDetails.fromJson(response.data);
        orders.removeWhere((element) => element.orderId == orderId);
        hasUploadedHomeImage = false;
        showToast("Order picked successfully");
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
}
