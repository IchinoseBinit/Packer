
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/hive_db/basket_dao.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/order/models/order_return_model.dart';
import 'package:packer/features/views/scanner/model/scan_result.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/post_basket_model.dart';
import 'package:provider/provider.dart';

class OrderReturnProvider extends ChangeNotifier {
  OrderReturnModel? selectedOrder;
  List<OrderReturnModel> returnOrder = [];
  late Box<Basket> basketBox;
  late BasketDao basketDao;
  List<Basket> baskets = [];

  List<String> rackNames = [];
  Map<String, List<OrderItems>> rackToOrderItems = {};

  List<String> scannedTagsList = [];

  Future<List<OrderReturnModel>> fetchOrderReturns() async {
    try {
      final response = await DioClient().request(
        url: AppUrls.orderReturnUrl,
        requestType: RequestType.getWithToken,
      );

      if (response.statusCode == 200) {
        returnOrder = (response.data as List)
            .map((order) => OrderReturnModel.fromJson(order))
            .toList();
      } else {
        throw Exception('Failed to load order returns');
      }

      // returnOrder = demoData.map((order) => OrderReturnModel.fromJson(order)).toList();

      // notifyListeners();
      return returnOrder;
    } catch (e) {
      return [];
    }
  }

  // assign selected model product according to rack
  void assignProductsToRack() {
    rackToOrderItems = {};
    rackNames.clear();
    for (final items in selectedOrder?.orderItems ?? <OrderItems>[]) {
      if (rackNames.contains(items.rackName)) {
        rackToOrderItems[items.rackName]!.add(items);
      } else {
        rackNames.add(items.rackName);
        rackToOrderItems[items.rackName] = [items];
      }
    }

    // sort rack names
    rackNames.sort();
    notifyListeners();
  }

  void onScanBasketTaped(BuildContext context, OrderReturnModel order) async {
    selectedOrder = order;
    assignProductsToRack();
    basketBox =
        await Hive.openBox('${HiveConstants.orderReturn}${order.orderId}');
    basketDao = BasketDao(basketBox);
    baskets = basketDao.getAll();
    if (!context.mounted) return;
    if (baskets.isNotEmpty) {
      initScannedTagsList();
      navigate(context, route: NavigationConstants.orderReturnDetailsRoute);
    } else {
      navigate(context, route: NavigationConstants.orderReturnScannerRoute);
    }
    notifyListeners();
  }

  bool get isCompleted {
    final orderItems = selectedOrder?.orderItems ?? [];

    final scannedSet = scannedTagsList.toSet(); // Convert to Set

    for (final item in orderItems) {
      if (!scannedSet.containsAll(item.unitTags)) {
        return false;
      }
    }
    return true;
  }

  // messages
  Future<void> getProductIntialMessage(
      BuildContext context, int productId) async {
    final product = selectedOrder?.orderItems
        .firstWhere((element) => element.productId == productId);
    if (product == null) return;
    Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
        context, "Scan ${product.unitTags.length} ${product.productName}");
  }

  Future<void> getRackIntialMessage(BuildContext context, int productId) async {
    final product = selectedOrder?.orderItems
        .firstWhere((element) => element.productId == productId);
    if (product == null) return;
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, "Scan Rack code - ${product.rackName}");
  }

  Future<void> getBasketIntialMessage(BuildContext context) async {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, "Scan Basket code ${selectedOrder?.basket}");
  }

  // on scan basket
  Future<ScanResult> onScanBasket(BuildContext context, String code) async {
    if (code
        .toLowerCase()
        .contains(selectedOrder?.basket.toLowerCase() ?? "")) {
      basketDao.addOrUpdateBasket(Basket(
          identifier: selectedOrder?.basket ?? "", productIdentifiers: []));
      baskets = basketDao.getAll();
      return ScanResult(success: true);
    } else {
      return ScanResult(
          success: false, message: "Invalid Basket Qr does not match");
    }
  }

  // on rack scan
  Future<ScanResult> onScanRack(
      BuildContext context, String code, int productId) async {
    final product = selectedOrder?.orderItems
        .where((element) => element.productId == productId)
        .firstOrNull;
    if (product == null) {
      return ScanResult(success: false, message: "Product not found");
    }
    if (code.toLowerCase().contains(product.rackName.toLowerCase())) {
      Provider.of<OrderReturnProvider>(context, listen: false)
          .getProductIntialMessage(context, productId);
      return ScanResult(success: true);
    } else {
      return ScanResult(
          success: false, message: "Invalid Rack Qr does not match");
    }
  }

  void initScannedTagsList() {
    // scannedTagsList.clear();
    scannedTagsList = baskets
        .map((basket) => basket.productIdentifiers)
        .expand((x) => x)
        .toList();
    print(scannedTagsList);
    notifyListeners();
  }

  // onScanProduct
  Future<ScanResult> onScanProduct(
      BuildContext context, int productId, String code) async {
    final product = selectedOrder?.orderItems
        .where((element) => element.productId == productId)
        .firstOrNull;
    if (product == null) {
      return ScanResult(success: false, message: "Product not found");
    }

    /// check if tag is already scanned
    if (scannedTagsList.contains(code)) {
      return ScanResult(success: false, message: "Tag already scanned");
    }

    /// check if tag is from product
    if (!product.unitTags.contains(code)) {
      return ScanResult(success: false, message: "Invalid tag");
    }
    scannedTagsList.add(code);
    basketDao.addOrUpdateBasket(Basket(
        identifier: selectedOrder?.basket ?? "",
        productIdentifiers: scannedTagsList));
    baskets = basketDao.getAll();
    if (scannedTagsList
            .where(
                (element) => element.split("-").first == productId.toString())
            .length ==
        product.unitTags.length) {
      notifyListeners();
      return ScanResult(success: true);
    }
    // scanned get this product count
    final scannedCount = scannedTagsList
        .where((element) => element.split("-").first == productId.toString())
        .length;
    final message =
        "Scan ${product.unitTags.length - scannedCount} ${product.productName} more";
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
    notifyListeners();
    return ScanResult(success: false);
  }

  bool isItemCompleted(int productId) {
    final product = selectedOrder?.orderItems
        .where((element) => element.productId == productId)
        .firstOrNull;
    if (product == null) return false;
    return product.unitTags.length ==
        scannedTagsList
            .where(
                (element) => element.split("-").first == productId.toString())
            .length;
  }

  // post order return
  Future<ScanResult> postOrderReturn(BuildContext context) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
          url: AppUrls.clearCancelledBasketUrl,
          requestType: RequestType.postWithToken,
          body: baskets.first.toPostBasketRequest());
      removeLoading(context);
      if (response.statusCode == 200) {
        basketDao.deleteBasket(baskets.first.identifier);
        baskets = basketDao.getAll();
        return ScanResult(success: true);
      } else {
        return ScanResult(
            success: false, message: "Failed to post order return");
      }
    } catch (e) {
      removeLoading(context);
      return ScanResult(success: false, message: e.toString());
    }
  }

  // scan basket
  Future<ScanResult> scanBasket(BuildContext context, String code) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
          url: AppUrls.clearCancelledBasketUrl,
          requestType: RequestType.postWithToken,
          body: baskets.first.toJson());
      removeLoading(context);
      if (response.statusCode == 200) {
        basketDao.deleteBasket(baskets.first.identifier);
        baskets = basketDao.getAll();
        return ScanResult(success: true);
      } else {
        return ScanResult(
            success: false, message: "Failed to post order return");
      }
    } catch (e) {
      removeLoading(context);
      return ScanResult(success: false, message: e.toString());
    }
  }
}
