import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/firebase_opt/firebase.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/auth/model/order_notification.dart';
import 'package:packer/features/views/auth/model/packer_summary.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:provider/provider.dart';

class HomeProvider with ChangeNotifier {
  User? _user;

  // getter : if _user is null, get user from token
  User get user {
    if (_user == null) {
      final map = Jwt.parseJwt(DioClient.token);
      _user = User.fromMap(map);
    }
    return _user!;
  }

  // reset : set _user to null
  void resetUser() {
    _user = null;
  }

  // check if user role is audit
  bool isAuditUser() {
    return user.role == UserRole.audit;
  }

  // check if user role is store manager
  bool isStoreManager() {
    return user.role == UserRole.manager;
  }

  // check if user role is driver
  bool isDriver() {
    return user.role == UserRole.driver;
  }

  // check if user is from main store ; return true if main store ; else false means it is from sub store
  bool isMainStore() {
    return packerSummary?.storeType.contains("main") ?? false;
  }

  bool isOnline = false;
  bool _isAvailable = false;
  bool isOrder = true;
  bool isOrderPicked = false;
  bool isLoading = false;
  bool isDelivered = false;
  OrderDetailModel? orderDetailModel;

  PackerSummary? packerSummary;

  // For audio notification sounds

  // notifications : order that are not assigned to any packer and comes from notification
  List<OrderNotification> notifications = [];
  // assigned orders : order that are assigned packer and comes from API
  List<OrderNotification> latestOrder = [];


  set isAvailable(val) {
    _isAvailable = val;
  }

  get isAvailable => _isAvailable;
  
  // [clearLatestOrder] : clear assigned orders 
  //
  // if call from payment then clear notifications and mark packer as not available
  clearLatestOrder({bool isFromPayment = true}) {
    latestOrder.clear();
    if (isFromPayment) {
      notifications.clear();
      isAvailable = false;
    }
    notifyListeners();
  }


  // initialize : initialize the home screen for packer
  //
  // if not first time then clear assigned orders
  //
  // if online then request permission and toggle firebase topic and fetch latest orders
  Future<void> initialize(BuildContext context,
      {bool isFirstTime = false}) async {
    if (!isFirstTime) {
      clearLatestOrder();
    }

    if (isOnline) {
      FirebaseAPI().requestPermission();
      toggleFirebaseTopic(context);
      fetchLatestOrders(isFirstTime: isFirstTime);
    }
  }


  // fetchpackerSummary : fetch packer summary
  //
  // if online then set isOnline to true
  Future<void> fetchpackerSummary() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.packerSummaryUrl,
      );

      packerSummary = PackerSummary.fromJson(response.data['data']);
      isOnline = packerSummary?.isOnline ?? false;
      notifyListeners();
    } catch (ex) {
      debugPrint('Error: $ex');
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
      debugPrint('Error: $ex');
    }
  }



  // removeFromLatestOrder : remove order from assigned orders
  //
  // if order exists in assigned orders then remove it
  void removeFromLatestOrder(String orderId) {
    latestOrder.removeWhere((element) => element.orderId == orderId);
    notifyListeners();
  }

  /// if online call this cause, they can't be viewing the latest orders
  Future<void> fetchLatestOrders({bool isFirstTime = false}) async {
    try {
      // step 1: clear assigned orders if not first time
      if (!isFirstTime) {
        clearLatestOrder(isFromPayment: false);
        isLoading = true;
        notifyListeners();
      }
      
      // step 2: fetch assigned orders
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.getLatestOrdersUrl,
      );

      // step 3: update assigned orders
      final List<dynamic> data = response.data;
      latestOrder =
          data.map((order) => OrderNotification.fromJson(order)).toList();

      if (latestOrder.isEmpty) {
        // fetchCreatedOrders();
      }

      // step 4: set loading to false
      isLoading = false;
      notifyListeners();
    } catch (ex) {
      debugPrint('Error: $ex');
      isLoading = false;
      notifyListeners();
    }
  }


  // _showNotificationPopup : show notification popup
  //
  // if order is not in assigned orders then show notification popup
  void _showNotificationPopup(BuildContext context, OrderNotification order) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    // step 1: Declare new variable
    bool hasNotification = false;

    // step 2: Check if order is in assigned orders from notifications
    if (notifications.any((element) => element.orderId == order.orderId)) {
      hasNotification = true;
    } 
    
    // step 3: Check if order is in assigned orders from order provider
    else if (orderProvider.orders
        .any((element) => element.orderId == order.orderId)) {
      hasNotification = true;
    } 
    
    // step 4: Check if order is in order details from order provider
    else if (orderProvider.orderDetails?.data.id.toString() ==
        order.orderId) {
      hasNotification = true;
    } 
    
    // step 5: Check if order is in order picked details from order provider
    else if (orderProvider.orderPickedDetails?.id.toString() ==
        order.orderId) {
      hasNotification = true;
    } 
    
    // step 6: Check if order is in completed order details from order provider
    else if (orderProvider.completedOrderDetails?.id.toString() ==
        order.orderId) {
      hasNotification = true;
    } 
    
    // step 7: Check if order is in unsettled orders from order provider
    else if (orderProvider.unsettledOrders?.data
            .any((element) => element.id.toString() == order.orderId) ??
        false) {
      hasNotification = true;
    } 
    
    // step 8: Check if order is in assigned orders from order provider
    else if (orderProvider.latestOrder
        .any((element) => element.orderId == order.orderId)) {
      hasNotification = true;
    }

    // step 9: add order to notifications if not found
    if (!hasNotification) {
      notifications.add(order);
      notifyListeners();
    }
  }

  // getpackerStatus : fetch the packer online status from API
  Future<void> getpackerStatus() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.packerOnlineStatus,
      );
      isOnline = response.data['is_online'];
      notifyListeners();
    } catch (ex) {
      debugPrint('Error: $ex');
    }
  }

  // updatepackerStatus : update the packer online status from API
  Future<bool> updatepackerStatus(bool status, BuildContext context,
      {bool showErrorDialog = true}) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.patchWithToken,
        url: AppUrls.packerOnlineStatus,
        body: {"is_online": status},
      );

      if (response.statusCode == 200) {
        status
            ? showToast("You are marked as Online")
            : showToast("You are marked as Offline");
        return true;
      }
      return false;
    } catch (ex) {
      if (!showErrorDialog) {
        return false;
      }
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text(ex.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      debugPrint('Error: $ex');
      return false;
    }
  }

  // not in use
  Future<void> updatepackerAvailability(bool status) async {
    try {
      await DioClient().request(
        requestType: RequestType.patchWithToken,
        url: AppUrls.packerAvailability,
        body: {"is_available": status},
      );
      isAvailable = status;
      notifyListeners();
    } catch (ex) {
      rethrow;
    }
  }

  toggleOnlineStatus(BuildContext context,
      {bool isFromWarehouse = false, Function()? onPressed}) async {
    isOnline = !isOnline;
    if (!isOnline) {
      HapticFeedback.heavyImpact();
    }
    final result = await updatepackerStatus(isOnline, context);
    result ? (isOnline = isOnline) : (isOnline = !isOnline);

    notifyListeners();

    if (isOnline) {
      FirebaseAPI().requestPermission();
      if (!isFromWarehouse && context.mounted) {
        notifications.clear();
        fetchLatestOrders();
        toggleFirebaseTopic(context);
      } else {
        onPressed?.call();
      }
      notifyListeners();
    } else {
      if (!isFromWarehouse && context.mounted) {
        toggleFirebaseTopic(context);
      }
      isAvailable = false;
      isOrder = false;
      isOrderPicked = false;
      isDelivered = false;
      notifyListeners();
    }
  }

  // not in use
  void markOrderPicked() {
    isOrder = false;
    isOrderPicked = true;
    notifyListeners();
  }

  // not in use
  void markArrived() {
    isDelivered = true;
    isOrderPicked = false;
    isOrder = false;
    notifyListeners();
  }

  // not in use
  updateAvailability(BuildContext context, bool isAvailable) async {
    try {
      if (isAvailable) {
        await updatepackerAvailability(true);
        if (!context.mounted) return;
        toggleFirebaseTopic(context);
      } else {
        await updatepackerAvailability(false);
        if (!context.mounted) return;
        toggleFirebaseTopic(context);
      }
    } catch (ex) {
      debugPrint('Error: $ex');
    }
  }

  toggleFirebaseTopic(BuildContext context) {
    FirebaseAPI().listenTopackerStatusNotifications(
        (order) => _showNotificationPopup(context, order));
  }
}
