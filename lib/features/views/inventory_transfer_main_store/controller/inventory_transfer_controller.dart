import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/inventory_transfer_main_store/model/inventory_transfer_carton_model.dart';
import 'package:packer/features/views/low_stock/model/carton_model.dart';
import 'package:packer/features/views/packer_transfer/model/basket_model.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_item_model.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_model.dart';
import 'package:packer/features/views/scanner/model/scan_result.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:provider/provider.dart';

class InventoryTransferController extends ChangeNotifier {
  List<TransferModel> inventoryTransferList = [];
  TransferModel? selectedInventoryTransfer;
  BasketModel? selectedBasket;
  TransferItemModel? selectedTransferItem;

  // rackList, rackProductMap
  List<String> rackList = [];
  Map<String, List<TransferItemModel>> rackProductMap = {};

  InventoryTransferCartonModel? cartonModel;

  List<String> scannedTags = [];

  int getScannedCount(int productId) {
    return scannedTags
        .where((e) => e.split('-').first == productId.toString())
        .length;
  }

  void arrangeItemAccordingToRack() {
    rackList = selectedInventoryTransfer?.items
            ?.map((e) => e.rack ?? '')
            .toSet()
            .toList() ??
        [];
    rackProductMap = {};
    for (var rack in rackList) {
      rackProductMap[rack] = selectedInventoryTransfer?.items
              ?.where((e) => e.rack == rack)
              .toList() ??
          [];
    }
    // sort rack list
    rackList.sort((a, b) => a.compareTo(b));
    notifyListeners();
  }

  List<String> getTags(bool remaining) {
    if (remaining) {
      // Return tags that have NOT been scanned
      return selectedTransferItem?.tags!
              .where((tag) => !scannedTags.contains(tag))
              .toList() ??
          [];
    } else {
      // Return tags that HAVE been scanned
      return selectedTransferItem?.tags!
              .where((tag) => scannedTags.contains(tag))
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

  Future<void> getInventoryTransferList() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.managerTransferUrl,
      );

      inventoryTransferList =
          (response.data as List).map((e) => TransferModel.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  onDetailsTap(BuildContext context, TransferModel transferModel) {
    selectedInventoryTransfer = transferModel;
    getInventoryTransferDetailsById();
    notifyListeners();
    navigate(context,
        route: NavigationConstants.inventoryTransferBasketListRoute);
  }

  // fetch inventory transfer details by id
  Future<void> getInventoryTransferDetailsById() async {
    try {
      final id = selectedInventoryTransfer?.id;
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url:
            AppUrls.managerTransferDetailsUrl.replaceFirst("id", id.toString()),
      );
      selectedInventoryTransfer = TransferModel.fromMap(response.data);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future removeTags(int product) async {
    scannedTags.removeWhere(
        (element) => element.split("-").first == product.toString());
    notifyListeners();
  }

  onBasketScanTapped(BuildContext context, BasketModel? basketModel) {
    selectedBasket = basketModel;
    notifyListeners();
    navigate(context,
        route: NavigationConstants.inventoryTransferScannerRoute,
        extra: {
          'scanBasket': true,
        });
  }

  void getBasketScanMessage(BuildContext context) {
    if (selectedBasket != null) {
      Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
          context, "Scan Basket Code ${selectedBasket!.identifier}");
    } else {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Basket Code");
    }
  }

  void getCartonScanMessage(BuildContext context) {
    if (cartonModel != null) {
      Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
          context, "Scan Carton Code ${cartonModel!.uniqueIdentifier}");
    } else {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Carton Code");
    }
  }

  void getProductScanMessage(BuildContext context) {
    final scannedCount = getScannedCount(selectedTransferItem!.product ?? 0);
    if (scannedCount > 0) {
      Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
          context,
          "Scan ${(selectedTransferItem?.quantity ?? 0) - scannedCount} ${selectedTransferItem?.productName} more");
    } else {
      Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
          context,
          "Scan ${selectedTransferItem?.quantity} ${selectedTransferItem?.productName}");
    }
  }

  Future<ScanResult> handleBasketScan(BuildContext context, String code) async {
    try {
      scannedTags.clear();
      if (selectedBasket != null && selectedBasket!.identifier == code) {
        await fetchBasketDetails(context, code);
        return ScanResult(
            success: true, message: "Basket Scanned Successfully");
      } else if (selectedBasket == null &&
          (selectedInventoryTransfer?.baskets
                  ?.any((element) => element.identifier == code) ??
              false)) {
        selectedBasket =
            selectedInventoryTransfer?.baskets?.firstWhere((element) => element.identifier == code);
        await fetchBasketDetails(context, code);
        return ScanResult(
            success: true, message: "Basket Scanned Successfully");
      }
      return ScanResult(success: false, message: "Invalid Basket Code");
    } catch (e) {
      return ScanResult(success: false, message: e.toString());
    }
  }

  fetchBasketDetails(BuildContext context, String code) async {
    try {
      final url = AppUrls.basketUrl.replaceAll(':id', code);
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );
      if (response.statusCode == 200) {
        selectedInventoryTransfer?.items = [];
        for (var element in response.data['products'] ?? []) {
          selectedInventoryTransfer?.items?.add(
            TransferItemModel.fromMap(element),
          );
        }
        arrangeItemAccordingToRack();
      } else {
        selectedInventoryTransfer?.items = [];
        throw response.data;
      }
    } catch (ex) {
      selectedInventoryTransfer?.items = [];
      rethrow;
    }
  }

  onItemScanTapped(BuildContext context, TransferItemModel transferItem) async {
    try {
      selectedTransferItem = transferItem;
      final firstTagCartonId = transferItem.tags?.first.split('-')[2] ?? "0";
      await fetchCartonInfo(context, firstTagCartonId);
      notifyListeners();
      if (context.mounted) {
        navigate(
          context,
          route: NavigationConstants.inventoryTransferScannerRoute,
          extra: {
            'scanCarton': true,
          },
        );
      }
    } catch (e) {
      showToast(e.toString());
    }
  }

  Future<ScanResult> handleCartonScan(BuildContext context, String code) async {
    try {
      if (cartonModel == null) {
        return ScanResult(success: false, message: "Carton Not Found");
      }
      if (cartonModel?.uniqueIdentifier != code) {
        return ScanResult(success: false, message: "Invalid Carton Code");
      }
      getProductScanMessage(context);
      return ScanResult(success: true, message: "Carton Scanned Successfully");
    } catch (e) {
      return ScanResult(success: false, message: e.toString());
    }
  }

  // handle product scan
  Future<ScanResult> handleProductScan(
      BuildContext context, String code) async {
    try {
      // already scanned
      if (scannedTags.contains(code)) {
        return ScanResult(success: false, message: "Product Already Scanned");
      }
      // check if product is in carton
      String cartonIdFromCode = code.split('-')[2];
      if (cartonModel?.id.toString() != cartonIdFromCode) {
        return ScanResult(success: false, message: "Product Not In Carton");
      }

      if (selectedTransferItem?.product.toString() != code.split('-').first) {
        return ScanResult(success: false, message: "Product not matched");
      }

      if (!selectedTransferItem!.tags!.contains(code)) {
        return ScanResult(success: false, message: "Product not matched");
      }

      scannedTags.add(code);
      int scannedCount = getScannedCount(selectedTransferItem!.product ?? 0);
      if (scannedCount == selectedTransferItem!.quantity) {
        await submitTransfer(context);
        getProductScanMessage(context);
        await fetchBasketDetails(context, selectedBasket!.identifier);
        return ScanResult(
            success: true, message: "Product Scanned Successfully");
      }
      getProductScanMessage(context);
      notifyListeners();
      return ScanResult(success: false);
    } catch (e) {
      getProductScanMessage(context);
      return ScanResult(success: false, message: e.toString());
    }
  }

  Future<void> fetchCartonInfo(BuildContext context, String code) async {
    try {
      final url = AppUrls.cartonDetailUrl.replaceAll(':id', code);
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );

      if (response.statusCode != 200) {
        throw response.data;
      }

      // final list = response.data as List;
      // if (list.isEmpty) {
      //   throw "No Carton Found";
      // }

      cartonModel = InventoryTransferCartonModel.fromJson(response.data);
      notifyListeners();
    } catch (ex) {
      rethrow;
    }
  }

  // submit transfer
  Future submitTransfer(BuildContext context) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.verifyUnitsUrl
            .replaceAll("id", selectedInventoryTransfer?.id.toString() ?? ""),
        body: {
          "product_id": selectedTransferItem?.product,
          "unit_tags": scannedTags
              .where((e) =>
                  e.split("-").first ==
                  selectedTransferItem?.product.toString())
              .toList(),
          "basket_identifier": selectedBasket?.identifier,
        },
      );
      removeTags(selectedTransferItem?.product ?? 0);
      if (response.statusCode == 200) {
        return true;
      }
      throw response.data;
    } catch (ex) {
      removeTags(selectedTransferItem?.product ?? 0);
      rethrow;
    }
  }
}
