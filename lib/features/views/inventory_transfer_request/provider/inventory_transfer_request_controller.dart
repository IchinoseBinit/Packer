import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/hive_db/hive_db_service.dart';
import 'package:packer/controllers/services/hive_db/inventory_request_dao.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/inventory_transfer_request/model/inventory_transfer_request_item_model.dart';
import 'package:packer/features/views/inventory_transfer_request/model/inventory_transfer_request_model.dart';
import 'package:packer/features/views/scanner/model/scan_result.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

class InventoryTransferRequestController extends ChangeNotifier {
  /// ============== STATE VARIABLE ==============

  // for inventory transfer request list
  List<InventoryTransferRequestModel> inventoryTransferRequestList = [];

  // for inventory transfer request item list
  InventoryTransferRequestModel? selectedInventoryTransferRequest;
  bool isLoading = false;
  List<InventoryTransferRequestItemModel> inventoryTransferRequestItemList = [];
  InventoryTransferRequestItemModel? selectedInventoryTransferRequestItem;

  List<String> rackList = [];
  Map<String, List<InventoryTransferRequestItemModel>>
      rackWiseInventoryTransferRequestItemList = {};

  // scanned tags list
  List<String> scannedTagsList = [];

  // local db setup
  late InventoryRequestDao inventoryRequestDao;
  late Box<InventoryTransferRequestItemModel> inventoryRequestBox;
  InventoryTransferRequestItemModel? localSelectedItem;
  List<String> localScannedTag = [];

  // basket code
  String? basketCode;

  /// ============== STATE VARIABLE END ==============

  /// arrange item according to rack
  void arrangeItemAccordingToRack() {
    rackList = inventoryTransferRequestItemList
        .map((e) => e.rackName ?? '')
        .toSet()
        .toList();
    rackWiseInventoryTransferRequestItemList = {};
    for (var rack in rackList) {
      rackWiseInventoryTransferRequestItemList[rack] =
          inventoryTransferRequestItemList
              .where((e) => e.rackName == rack)
              .toList();
    }
    // sort rack list
    rackList.sort((a, b) => a.compareTo(b));
    notifyListeners();
  }

  void onRequestTap(
      BuildContext context, InventoryTransferRequestModel transferItem) {
    selectedInventoryTransferRequest = transferItem;
    initLocal();
    navigate(
      context,
      route: NavigationConstants.inventoryTransferRequestDetailsRoute,
    );
    getInventoryTransferRequestItemList();
    notifyListeners();
  }

  // init local
  Future<void> initLocal() async {
    scannedTagsList.clear();
    inventoryRequestBox = await HiveDBService.openInventoryTransferRequestBox(
        selectedInventoryTransferRequest!.id.toString());
    inventoryRequestDao = InventoryRequestDao(inventoryRequestBox);
    final local = inventoryRequestDao.getAll();
    for (var item in local) {
      scannedTagsList.addAll(item.tags ?? []);
    }
    notifyListeners();
  }

  // get product scanned count
  int getScannedCount(int productId, {bool fromLocal = false}) {
    if (fromLocal) {
      return localScannedTag
          .where((e) => e.split("-").first == productId.toString())
          .length;
    }
    return scannedTagsList
        .where((e) => e.split("-").first == productId.toString())
        .length;
  }

  void setSelectedInventoryTransferRequestItem(
      BuildContext context, InventoryTransferRequestItemModel item) {
    selectedInventoryTransferRequestItem = item;
    notifyListeners();
    navigate(
      context,
      route: NavigationConstants.inventoryTransferRequestScannerRoute,
    );
  }

  // void setSelectedLocalInventoryTransferRequestItem(
  //     BuildContext context, InventoryTransferRequestItemModel item) {
  //   localSelectedItem = item;
  //   initLocal();
  //   notifyListeners();
  //   Provider.of<InventoryTransferRequestController>(context, listen: false)
  //       .getLocalProductScanMessage(context);
  //   navigateReplacement(context,
  //       route: NavigationConstants.inventoryTransferRequestScannerRoute,
  //       extra: {"scanLocal": true});
  // }

  // remove scanned tag
  void removeScannedTag(String productId,
      {bool isSuccess = false, bool fromLocal = false}) {
    if (fromLocal) {
      localScannedTag.removeWhere((tag) => tag.split("-").first == productId);
    } else {
      scannedTagsList.removeWhere((tag) => tag.split("-").first == productId);
    }
    if (isSuccess) {
      inventoryTransferRequestItemList
          .removeWhere((item) => item.productId == int.parse(productId));
      arrangeItemAccordingToRack();
    }
    notifyListeners();
  }

  // scanBasketCode
  Future<void> scanBasketCode(BuildContext context) async {
    await navigate(context,
        route: NavigationConstants.inventoryTransferRequestScannerRoute,
        extra: {"scanBasket": true});
    await getInventoryTransferRequestItemList();
  }

  void getProductScanMessage(BuildContext context) {
    if (selectedInventoryTransferRequestItem == null) return;
    int scannedCount =
        getScannedCount(selectedInventoryTransferRequestItem?.productId ?? 0);
    if (scannedCount > 0) {
      final scanMessage =
          "Scan ${(selectedInventoryTransferRequestItem?.quantity ?? 0) - scannedCount} ${selectedInventoryTransferRequestItem?.productName} More";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, scanMessage);
    } else {
      final scanMessage =
          "Scan ${selectedInventoryTransferRequestItem?.quantity} ${selectedInventoryTransferRequestItem?.productName}";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, scanMessage);
    }
  }

  void getLocalProductScanMessage(BuildContext context) {
    if (localSelectedItem == null) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Product Code");
      return;
    }
    int scannedCount =
        getScannedCount(localSelectedItem?.productId ?? 0, fromLocal: true);
    if (scannedCount > 0) {
      final scanMessage =
          "Scan ${(localSelectedItem?.tags?.length ?? 0) - scannedCount} ${localSelectedItem?.productName} More";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, scanMessage);
    } else {
      final scanMessage =
          "Scan ${localSelectedItem?.tags?.length} ${localSelectedItem?.productName}";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, scanMessage);
    }
  }

  List<String> getTags(bool remaining) {
    if (remaining) {
      // Return tags that have NOT been scanned
      return localSelectedItem?.tags!
              .where((tag) => !localScannedTag.contains(tag))
              .toList() ??
          [];
    } else {
      // Return tags that HAVE been scanned
      return localSelectedItem?.tags!
              .where((tag) => localScannedTag.contains(tag))
              .toList() ??
          [];
    }
  }

  void showProductTags(BuildContext context) {
    final remainingTags = getTags(true);
    final completedTags = getTags(false);
    // show modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                Flexible(
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
                Flexible(
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

  Future<void> addItemToLocal() async {
    final productId =
        selectedInventoryTransferRequestItem!.productId.toString();
    final getLocalItem = inventoryRequestDao.getInventoryRequest(productId);
    if (getLocalItem != null) {
      getLocalItem.tags = scannedTagsList
          .where((tag) => tag.split("-").first == productId)
          .toList();
      inventoryRequestDao.addOrUpdateInventoryRequest(getLocalItem);
    } else {
      selectedInventoryTransferRequestItem!.tags = scannedTagsList
          .where((tag) => tag.split("-").first == productId)
          .toList();
      inventoryRequestDao
          .addOrUpdateInventoryRequest(selectedInventoryTransferRequestItem!);
    }
    await initLocal();
    notifyListeners();
  }

  Future<ScanResult> handleProductScan(
      BuildContext context, String code) async {
    try {
      if (selectedInventoryTransferRequestItem == null) {
        return ScanResult(success: false, message: "No transfer item selected");
      }
      // check if already scanned
      if (scannedTagsList.contains(code)) {
        return ScanResult(success: false, message: "QR: $code already scanned");
      }
      // check same product tag
      if (code.split("-").first !=
          selectedInventoryTransferRequestItem!.productId.toString()) {
        return ScanResult(
            success: false, message: "Invalid QR - Product does not match");
      }
      scannedTagsList.add(code);
      // check if required tags are scanned
      if (scannedTagsList.length ==
          selectedInventoryTransferRequestItem!.quantity) {
        await addItemToLocal();
        return ScanResult(
            success: true, message: "Product scanned successfully");
      }
      getProductScanMessage(context);
      return ScanResult(success: false);
    } catch (e) {
      return ScanResult(success: false, message: e.toString());
    }
  }

  Future<ScanResult> handleLocalProductScan(
      BuildContext context, String code) async {
    try {
      // check if already scanned
      if (localScannedTag.contains(code)) {
        return ScanResult(success: false, message: "QR: $code already scanned");
      }
      if (localScannedTag.isEmpty) {
        final localItem =
            inventoryRequestDao.getInventoryRequest(code.split("-").first);
        if (localItem == null) {
          return ScanResult(
              success: false, message: "Invalid QR - Product does not match");
        }
        localSelectedItem = localItem;
      } else if (!localSelectedItem!.tags!.contains(code)) {
        return ScanResult(
            success: false, message: "Invalid QR - Product does not match");
      }
      localScannedTag.add(code);
      // check if required tags are scanned
      if (localScannedTag.length == localSelectedItem!.tags?.length) {
        await submitProductTags(context);
        getLocalProductScanMessage(context);
        return ScanResult(
            success: true, message: "Product scanned successfully");
      }
      getLocalProductScanMessage(context);
      notifyListeners();
      return ScanResult(success: false);
    } catch (e) {
      getLocalProductScanMessage(context);
      return ScanResult(success: false, message: e.toString());
    }
  }

  /// handle basket scan
  Future<ScanResult> handleBasketScan(BuildContext context, String code) async {
    // check contain basket
    try {
      if (!code.contains("basket")) {
        return ScanResult(success: false, message: "Please scan basket code");
      }

      await checkBasketIdentifier(code);

      basketCode = code;
      // remove previous scanned tags
      localScannedTag.clear();
      localSelectedItem = null;
      notifyListeners();
      Provider.of<InventoryTransferRequestController>(context, listen: false)
          .getLocalProductScanMessage(context);
      navigateReplacement(context,
          route: NavigationConstants.inventoryTransferRequestScannerRoute,
          extra: {"scanLocal": true});
      return ScanResult(success: true, message: "Basket scanned successfully");
    } catch (e) {
      return ScanResult(success: false, message: e.toString());
    }
  }

  /// ================= API CALL START HERE =================

  /// [getInventoryTransferRequestList]
  Future getInventoryTransferRequestList() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.inventoryTransferRequestList,
      );
      final dataList = response.data['data'] as List;
      inventoryTransferRequestList = dataList
          .map((e) => InventoryTransferRequestModel.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future checkBasketIdentifier(String code) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.scanReturnBasketUrl,
        body: {
          "basket_identifier": code,
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
      throw response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// [getInventoryTransferRequestItemList]
  Future getInventoryTransferRequestItemList({bool fromBuilder = false}) async {
    try {
      if (selectedInventoryTransferRequest == null) {
        return;
      }

      isLoading = true;
      if (!fromBuilder) {
        notifyListeners();
      }

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.inventoryTransferRequestDetails.replaceFirst(
            ":id", selectedInventoryTransferRequest!.id.toString()),
      );
      final dataList = response.data['items'] as List;
      inventoryTransferRequestItemList = dataList
          .map((e) => InventoryTransferRequestItemModel.fromJson(e))
          .toList();
      arrangeItemAccordingToRack();
      isLoading = false;
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  /// [submitProductTags]
  Future<void> submitProductTags(BuildContext context) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.returnProductToWarehouseUrl,
        body: {
          "request_id": selectedInventoryTransferRequest!.id,
          "product_units": localScannedTag,
          "basket_identifier": basketCode,
        },
      );
      if (context.mounted) {
        removeLoading(context);
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw response.data;
      }

      // after success
      await inventoryRequestDao
          .deleteInventoryRequest(localSelectedItem!.productId.toString());
      removeScannedTag(localSelectedItem!.productId.toString(),
          fromLocal: true);
      localSelectedItem = null;
      getInventoryTransferRequestItemList();
      initLocal();
      notifyListeners();
    } catch (e) {
      initLocal();
      removeScannedTag(localSelectedItem!.productId.toString(),
          fromLocal: true);
      if (context.mounted) {
        removeLoading(context);
      }
      rethrow;
    }
  }

  /// ================= API CALL END HERE =================
}
