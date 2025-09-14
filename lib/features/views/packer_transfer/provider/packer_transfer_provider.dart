import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/packer_transfer/model/basket_model.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_item_model.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_model.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class PackerTransferProvider extends ChangeNotifier {
  var transferList = <TransferModel>[];
  var transferListLoading = false;
  String? scanMessage;
  TransferModel? selectedTransferModel;
  BasketModel? selectedBasketModel;
  var selectedTransferModelLoading = false;
  String? role;

  List<String> scanTagsList = [];

  bool hasScanned = false;

  void setRole(String value) {
    role = value;
  }

  resetHasScanned() {
    hasScanned = false;
  }

  List<String> rackList = [];
  Map<String, List<TransferItemModel>> rackMap = {};

  arrangeRackTransferItem() {
    rackMap.clear();
    rackList.clear();

    selectedTransferModel?.items?.forEach((element) {
      if (!rackList.contains(element.rack)) {
        rackList.add(element.rack ?? '');
      }

      rackMap.putIfAbsent(element.rack ?? '', () => []);
      rackMap[element.rack ?? '']!.add(element);
    });

    rackList.sort((a, b) => a.compareTo(b));
    rackList = rackList.reversed.toList();

    notifyListeners();
  }

  String getScanMessage(int id) {
    log("Message Product Id: $id");
    for (var element in selectedTransferModel?.items ?? <TransferItemModel>[]) {
      if (element.product == id) {
        return "Scan ${(element.quantity ?? 0) - element.itemScanCount} ${element.productName}";
      }
    }
    return "";
  }

  bool showCompleteButton() {
    if (selectedTransferModel?.items != null) {
      for (var element in selectedTransferModel!.items!) {
        if (element.itemScanCount != element.quantity) {
          return false;
        }
      }
    }
    return true;
  }

  void onDetailsTaped(BuildContext context, TransferModel data) async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.isMainStore() == false) {
      selectedTransferModel = data;
      // final navigateResult = await navigate(
      //   context,
      //   route: NavigationConstants.inventoryScanScreenRoute,
      //   extra: {
      //     "identifier": data.identifier,
      //   },
      // );
      if (context.mounted) {
        scanTagsList.clear();
        notifyListeners();
        fetchTransferDetails(context, selectedTransferModel?.id ?? 0);
        navigateReplacement(context,
            route: NavigationConstants.basketListRoute);
      }
    } else {
      fetchTransferDetails(context, data.id ?? 0);
      navigate(context, route: NavigationConstants.basketListRoute);
    }
  }

  Future<void> fetchTransferList(BuildContext context) async {
    try {
      transferListLoading = true;
      transferList.clear();
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final url = homeProvider.isMainStore() == true
          ? AppUrls.packerTransferUrl
          : AppUrls.managerTransferUrl;
      final response = await DioClient()
          .request(requestType: RequestType.getWithToken, url: url);
      if (response.statusCode == 200) {
        final data = response.data as List;
        for (var item in data) {
          transferList.add(TransferModel.fromMap(item));
        }
        notifyListeners();
      } else {
        ErrorHandler.alertDialog(context, 'Failed to fetch transfer list');
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
    } finally {
      transferListLoading = false;
      notifyListeners();
    }
  }

  bool scanCountOrder(BuildContext context, int cartItemId) {
    for (var element in selectedTransferModel?.items ?? <TransferItemModel>[]) {
      if (element.product == cartItemId) {
        if (element.itemScanCount == element.quantity) {
          ErrorHandler.alertDialog(context, "Item already scanned");
          return false;
        }

        element.itemScanCount++;
        if (element.itemScanCount == element.quantity) {
          showToast("Item scanned successfully");
          notifyListeners();
          return true;
        } else {
          final scanMessage =
              "Scan ${(element.quantity ?? 0) - element.itemScanCount} more ${element.productName}";
          Provider.of<ScanMessageProvider>(context, listen: false)
              .setMessage(context, scanMessage);
        }
        notifyListeners();
        return false;
      }
    }
    ErrorHandler.alertDialog(context, "Item not found");
    notifyListeners();
    return false;
  }

  // get tags completed or not (bool remaining)
  List<String> getTagsRemaining(
      BuildContext context, int productId, bool remaining) {
    final item = selectedTransferModel?.items?.firstWhere(
      (element) => element.product == productId,
      orElse: () => TransferItemModel(),
    );

    if (item == null || item.tags == null) {
      // ErrorHandler.alertDialog(context, "Item not found");
      return [];
    }

    if (remaining) {
      // Return tags that have NOT been scanned
      return item.tags!.where((tag) => !scanTagsList.contains(tag)).toList();
    } else {
      // Return tags that HAVE been scanned
      return item.tags!.where((tag) => scanTagsList.contains(tag)).toList();
    }
  }

  void showProductTags(BuildContext context, int productId) {
    // get item
    final item = selectedTransferModel?.items?.firstWhere(
      (element) => element.product == productId,
      orElse: () => TransferItemModel(),
    );
    if (item == null) {
      ErrorHandler.alertDialog(context, "Item not found");
      return;
    }
    final remainingTags = getTagsRemaining(context, productId, true);
    final completedTags = getTagsRemaining(context, productId, false);
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
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: remainingTags.length,
                  itemBuilder: (context, index) {
                    return Text(remainingTags[index],
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 13.sp,
                                ));
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 12.h);
                  },
                ),
              ],
              // 12.h
              SizedBox(height: 12.h),
              if (completedTags.isNotEmpty) ...[
                Text("Completed Tags",
                    style: Theme.of(context).textTheme.labelLarge),
                // 12.h
                SizedBox(height: 12.h),
                ListView.separated(
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
              ],
            ],
          ),
        );
      },
    );
  }

  Future<bool> scanProduct(BuildContext context, int productId, String code,
      MobileScannerController controller) async {
    if (scanTagsList.contains(code)) {
      removeLoading(context);
      ErrorHandler.alertDialog(context, "Tag already scanned");

      return false;
    }

    final item = selectedTransferModel?.items?.firstWhere(
      (element) => element.product == productId,
      orElse: () => TransferItemModel(),
    );
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.isMainStore() == false) {
      if (item != null && (item.tags?.contains(code) ?? false)) {
        scanTagsList.add(code);
        final scanMessage =
            "Scan ${(item.quantity ?? 0) - item.itemScanCount} more ${item.productName}";
        Provider.of<ScanMessageProvider>(context, listen: false)
            .setMessage(context, scanMessage);
      } else {
        removeLoading(context);
        await ErrorHandler.alertDialog(
            context, "Invalid QR ${detectQrMessage(code)}");
        return false;
      }
    } else {
      scanTagsList.add(code);
      final scanMessage =
          "Scan ${(item?.quantity ?? 0) - (item?.itemScanCount ?? 0)} more ${item?.productName}";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, scanMessage);
    }
    final isScanned = scanCountOrder(context, productId);
    if (isScanned) {
      if (role == "main") {
        await controller.stop();
        final result = await navigateReplacement(
          context,
          route: NavigationConstants.scanRackRoute,
          extra: {
            "productId": productId,
            "forDamage": true,
          },
        );

        if (result != true) {
          await controller.start();
        }

        return true;
      }
      final success = await postScannedTags(context, productId);

      if (success) {
        return true;
      } else {
        removeScanTags(productId);
        item?.itemScanCount = 0;
        ErrorHandler.alertDialog(context, "Failed to submit scan tag");
        scanTagsList.clear();
        notifyListeners();
        return false;
      }
    }
    removeLoading(context);
    return false;
  }

  // remove particular productid scan tags
  void removeScanTags(int productId) {
    scanTagsList
        .removeWhere((element) => element.contains(productId.toString()));
    notifyListeners();
  }

  onBasketScanTapped(BuildContext context, BasketModel? basket) {
    selectedBasketModel = basket;
    notifyListeners();
    navigate(context, route: NavigationConstants.basketScanScreenRoute, extra: {
      "forOrder": false,
      "basketCode": basket?.identifier,
    });
  }

  // basket scan
  bool scanBasketCode(BuildContext context, String code) {
    if (selectedBasketModel == null) {
      if (selectedTransferModel?.baskets?.any((basket) =>
              basket.identifier.toLowerCase().contains(code.toLowerCase())) ??
          false) {
        selectedBasketModel = selectedTransferModel?.baskets?.firstWhere(
          (basket) =>
              basket.identifier.toLowerCase().contains(code.toLowerCase()),
        );
        // removeLoading(context);
        fetchBasketDetails(context, selectedBasketModel?.identifier ?? "");
        return true;
      }
    }
    if (selectedBasketModel?.identifier
            .toLowerCase()
            .contains(code.toLowerCase()) ??
        false) {
      scanTagsList.clear();
      notifyListeners();
      removeLoading(context);
      fetchBasketDetails(context, code);
      return true;
    }
    return false;
  }

  // itemTaped
  Future<void> itemTaped(BuildContext context, TransferItemModel? item) async {
    if (item == null) {
      ErrorHandler.alertDialog(context, "Item not found");
      return;
    }
    final scanMessage = getScanMessage(item.product ?? 0);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.isMainStore() == false) {
      if (item.rack != null && item.rack!.isNotEmpty) {
        final result = await navigate(context,
            route: NavigationConstants.scanRackRoute,
            extra: {"rack": item.rack, "productId": item.product});
        if (result == true && context.mounted) {
          Provider.of<ScanMessageProvider>(context, listen: false)
              .setMessage(context, scanMessage);
          navigate(
            context,
            route: NavigationConstants.productScanScreenRoute,
            extra: {
              "forTransfer": true,
              "productId": item.product,
            },
          );
        }
        return;
      }
      showYesNo(context).then((value) async {
        final result = await navigate(
          context,
          route: NavigationConstants.scanRackRoute,
          extra: {
            "productId": item.product,
          },
        );
        return;
      });
    } else {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, scanMessage);
      navigate(
        context,
        route: NavigationConstants.productScanScreenRoute,
        extra: {
          "forTransfer": true,
          "productId": item.product,
        },
      );
    }
  }

  // show yes no for update product rack
  Future<bool?> showYesNo(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: const Text("Assign a rack?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // post scanned tags
  Future<bool> postScannedTags(BuildContext context, int productId) async {
    try {
      showLoading(context);
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final url = homeProvider.isMainStore() == true
          ? AppUrls.scanUnitUrl
          : AppUrls.verifyUnitsUrl;
      final urlValue =
          url.replaceAll('id', selectedTransferModel?.id?.toString() ?? '0');
      if (scanTagsList.isEmpty) {
        ErrorHandler.alertDialog(context, 'No tags to post');
        removeLoading(context);
        return false;
      } else {
        final response = await DioClient().request(
          requestType: RequestType.postWithToken,
          url: urlValue,
          body: {
            "product_id": productId,
            "unit_tags": scanTagsList,
            if (homeProvider.isMainStore() == false)
              "basket_identifier": selectedBasketModel?.identifier,
          },
        );
        if (response.statusCode == 200) {
          showToast('Tags posted successfully');
          scanTagsList.clear();
          notifyListeners();
          removeLoading(context);
          return true;
        } else {
          ErrorHandler.alertDialog(context, 'Failed to post tags');
          removeLoading(context);
          return false;
        }
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
      removeLoading(context);
      return false;
    }
  }

  Future<bool> postDamageProductTags(
      BuildContext context, int productId, String rackName) async {
    try {
      showLoading(context);
      final url = AppUrls.verifyDamageProductUrl;
      final urlValue =
          url.replaceAll('id', selectedTransferModel?.id?.toString() ?? '0');
      if (scanTagsList.isEmpty) {
        ErrorHandler.alertDialog(context, 'No tags to post');
        removeLoading(context);
        return false;
      } else {
        final response = await DioClient().request(
          requestType: RequestType.postWithToken,
          url: urlValue,
          body: {
            "product_id": productId,
            "unit_tags": scanTagsList,
            "rack_identifier": rackName,
            "basket_identifier": selectedBasketModel?.identifier,
          },
        );
        if (response.statusCode == 200) {
          showToast('Tags posted successfully');
          scanTagsList.clear();
          notifyListeners();
          removeLoading(context);
          return true;
        } else {
          removeLoading(context);
          if (context.mounted) {
            await ErrorHandler.alertDialog(context, 'Failed to post tags');
          }
          return false;
        }
      }
    } catch (ex) {
      removeLoading(context);

      await ErrorHandler.alertDialog(context, ex.toString());

      return false;
    }
  }

  // update product rack
  void updateRackOnModel(int productId, String rack) {
    for (var element in selectedTransferModel?.items ?? <TransferItemModel>[]) {
      if (element.product == productId) {
        element.rack = rack;
      }
    }
    notifyListeners();
  }

  Future<bool> updateRack(
      BuildContext context, String code, int productId) async {
    try {
      final url = AppUrls.updateRackUrl;
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "rack_identifier": code,
          "product_id": productId,
        },
      );
      if (response.statusCode == 200 && context.mounted) {
        updateRackOnModel(productId, code);
        // move navigation after loading is removed

        // set message
        Provider.of<ScanMessageProvider>(context, listen: false)
            .setMessage(context, getScanMessage(productId));

        return true;
      } else {
        ErrorHandler.alertDialog(context, 'Failed to update rack');
        return false;
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
      return false;
    }
  }

  // complete transfer
  Future<void> completeTransfer(BuildContext context) async {
    try {
      showLoading(context);
      final id = selectedTransferModel?.id;
      if (id == null) {
        ErrorHandler.alertDialog(context, 'Transfer ID is null');
        return;
      }
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final url = homeProvider.isMainStore() == true
          ? AppUrls.completeTransferUrl
          : AppUrls.acceptTransferUrl;
      final response = await DioClient().request(
          requestType: RequestType.postWithToken,
          url: url.replaceAll('id', id.toString()),
          body: {
            "basket_identifier": selectedBasketModel?.identifier,
          });
      if (response.statusCode == 200) {
        showToast('Transfer completed successfully');
        selectedTransferModel?.baskets?.removeWhere(
          (element) => element.identifier == selectedBasketModel?.identifier,
        );
        navigatePop(context, true);
        removeLoading(context);
      } else {
        ErrorHandler.alertDialog(context, 'Failed to complete transfer');
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
    }
  }

  fetchBasketDetails(BuildContext context, String code) async {
    try {
      selectedTransferModelLoading = true;
      final url = AppUrls.basketUrl.replaceAll(':id', code);
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );
      if (response.statusCode == 200) {
        selectedTransferModel?.items = [];
        for (var element in response.data['products'] ?? []) {
          selectedTransferModel?.items?.add(
            TransferItemModel.fromMap(element),
          );
        }
        arrangeRackTransferItem();
      } else {
        ErrorHandler.alertDialog(context, 'Failed to fetch basket details');
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
    } finally {
      selectedTransferModelLoading = false;
      notifyListeners();
    }
  }

  // details
  Future<void> fetchTransferDetails(BuildContext context, int id) async {
    try {
      selectedTransferModelLoading = true;
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final url = homeProvider.isMainStore() == true
          ? AppUrls.packerTransferDetailsUrl
          : AppUrls.managerTransferDetailsUrl;
      final urlValue = url.replaceAll('id', id.toString());
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: urlValue,
      );
      if (response.statusCode == 200) {
        selectedTransferModel = TransferModel.fromMap(response.data);
        notifyListeners();
      } else {
        ErrorHandler.alertDialog(context, 'Failed to fetch transfer details');
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
    } finally {
      selectedTransferModelLoading = false;
      notifyListeners();
    }
  }
}
