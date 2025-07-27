import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/extensions/list_extension.dart';
import 'package:packer/controllers/firebase_opt/firebase.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/auth/model/order_notification.dart';
import 'package:packer/features/views/auth/model/packer_summary.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';

class HomeProvider with ChangeNotifier {
  User? _user;

  User get user {
    if (_user == null) {
      final map = Jwt.parseJwt(DioClient.token);
      _user = User.fromMap(map);
    }
    return _user!;
  }

  void resetUser() {
    _user = null;
  }

  bool isAuditUser() {
    return user.role == UserRole.audit;
  }

  bool isStoreManager() {
    return user.role == UserRole.manager;
  }

  bool isDriver() {
    return user.role == UserRole.driver;
  }

  bool isMainStore() {
    return packerSummary?.storeType.contains("main") ?? false;
  }

  bool isOnline = false;
  bool _isAvailable = false;
  bool isOrder = true;
  bool isOrderPicked = false;
  bool isLoading = false;
  String customerName = 'Samarth';
  int packingTime = 2;
  bool isDelivered = false;
  String paymentMethod = 'Cash on delivery';
  bool isMapFullScreen = false;
  OrderDetailModel? orderDetailModel;

  PackerSummary? packerSummary;

  // For audio notification sounds

  List<OrderNotification> notifications = [];
  List<OrderNotification> latestOrder = [];

  final dio = Dio();
  OrderProvider orderProvider = OrderProvider();

  set isAvailable(val) {
    _isAvailable = val;
  }

  get isAvailable => _isAvailable;

  clearLatestOrder({bool isFromPayment = true}) {
    latestOrder.clear();
    if (isFromPayment) {
      isAvailable = false;
    }
    notifyListeners();
  }

  Future<void> initialize({bool isFirstTime = false}) async {
    if (!isFirstTime) {
      clearLatestOrder();
    }

    if (isOnline) {
      FirebaseAPI().requestPermission();
      if (isAvailable) {
        fetchCreatedOrders();
      }
      FirebaseAPI().listenTopackerStatusNotifications(_showNotificationPopup);
      fetchLatestOrders(isFirstTime: isFirstTime);
    }
  }

  Future<void> fetchpackerSummary() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.packerSummaryUrl,
      );

      packerSummary = PackerSummary.fromJson(response.data['data']);
      isOnline = packerSummary?.isOnline ?? false;
      // isAvailable = packerSummary?.isAvailable ?? false;
      notifyListeners();
    } catch (ex) {
      print('Error: $ex');
    }
  }

  /// if available fetch this as they need to see the created orders
  Future<void> fetchCreatedOrders() async {
    try {
      var url = AppUrls.getOrdersByStatusUrl;
      url += OrderStatusType.created.toString();

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );

      final List<dynamic> data = response.data;
      notifications =
          data.map((order) => OrderNotification.fromJson(order)).toList();
      notifyListeners();
    } catch (ex) {
      print('Error: $ex');
      // throw Exception('Failed to load carts: $ex');
    }
  }

  /// if online call this cause, they can't be viewing the latest orders
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

      if (latestOrder.isEmpty) {
        fetchCreatedOrders();
      }
      isLoading = false;

      notifyListeners();
    } catch (ex) {
      print('Error: $ex');
      isLoading = false;
      notifyListeners();
      throw Exception('Failed to load carts: $ex');
    }
  }

  // void initScanMessage(int productId) {
  //   if (kDebugMode) {
  //     showToast('Item Id: $productId');
  //   }
  //   for (var element in orderDetailModel?.productDetails ?? []) {
  //     if (element.id == productId) {
  //       scanMessage =
  //           "Scan ${element.quantity - element.itemScanCount} ${element.productName}";
  //       notifyListeners();
  //       return;
  //     }
  //   }
  // }

  void _showNotificationPopup(OrderNotification order) {
    final hasNotification = notifications
        .firstWhereOrNull((element) => element.orderId == order.orderId);
    if (hasNotification == null) {
      notifications.add(order);
      notifyListeners();
    }
  }

  Future<void> getpackerStatus() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.packerOnlineStatus,
      );
      isOnline = response.data['is_online'];
      notifyListeners();
    } catch (ex) {
      print('Error: $ex');
    }
  }

  // Future<void> acknowledgeOrder(int index) async {
  //   try {
  //     final id = notifications[index].orderId;
  //     final response = await DioClient().request(
  //       requestType: RequestType.postWithToken,
  //       url: AppUrls.acknowledgeOrderUrl.replaceAll("id", id),
  //     );
  //     if (response.statusCode == 200) {
  //       notifications.removeWhere((element) => element.orderId == id);
  //       notifyListeners();
  //     }
  //   } catch (ex) {
  //     showToast(ex.toString());
  //     print('Error: $ex');
  //   }
  // }

  Future<void> updatepackerStatus(bool status) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.patchWithToken,
        url: AppUrls.packerOnlineStatus,
        body: {"is_online": status},
      );
    } catch (ex) {
      print('Error: $ex');
    }
  }

  Future<void> updatepackerAvailability(bool status) async {
    try {
      await DioClient().request(
        requestType: RequestType.patchWithToken,
        url: AppUrls.packerAvailability,
        body: {"is_available": status},
      );
      isAvailable = status;
      fetchCreatedOrders();
      notifyListeners();
    } catch (ex) {
      rethrow;
    }
  }

  void toggleOnlineStatus({bool isFromWarehouse = false}) async {
    isOnline = !isOnline;
    if (!isOnline) {
      HapticFeedback.heavyImpact();
    }
    notifyListeners();
    await updatepackerStatus(isOnline);
    if (isOnline) {
      FirebaseAPI().requestPermission();
      if (!isFromWarehouse) {
        fetchLatestOrders();
        FirebaseAPI().listenTopackerStatusNotifications(_showNotificationPopup);
      }
      notifyListeners();
    } else {
      if (!isFromWarehouse) {
        toggleFirebaseTopic();
      }
      isAvailable = false;
      isOrder = false;
      isOrderPicked = false;
      isDelivered = false;
      notifyListeners();
    }
  }

  void markOrderPicked() {
    isOrder = false;
    isOrderPicked = true;
    notifyListeners();
  }

  void markArrived() {
    isDelivered = true;
    isOrderPicked = false;
    isOrder = false;
    notifyListeners();
  }

  updateAvailability({String? topicName}) async {
    try {
      if (topicName != null) {
        await updatepackerAvailability(true);
        toggleFirebaseTopic(topicName: topicName);
      } else {
        await updatepackerAvailability(false);
        toggleFirebaseTopic();
      }
    } catch (ex) {
      // rethrow;
    }
  }

  toggleFirebaseTopic({String? topicName}) {
    if (topicName != null) {
      FirebaseAPI().packerStatus(topicName);
      FirebaseAPI().listenTopackerStatusNotifications(_showNotificationPopup);
    } else {
      if (FirebaseAPI().topicName.isEmpty) {
        // TODO: Check here
        // FirebaseAPI().topicName = packerSummary?.topicName ?? "";
      }
      FirebaseAPI().unsubscribepackerStatus();
    }
  }
}
