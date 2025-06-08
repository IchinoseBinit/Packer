import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/packer_transfer/model/basket_model.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_item_model.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_model.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
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
    if (role?.contains("main") == false) {
      selectedTransferModel = data;
      final navigateResult = await navigate(
        context,
        route: NavigationConstants.inventoryScanScreenRoute,
        extra: {
          "identifier": data.identifier,
        },
      );
      if ((navigateResult ?? false) && context.mounted) {
        scanTagsList.clear();
        notifyListeners();
        fetchTransferDetails(selectedTransferModel?.id ?? 0);
        navigateReplacement(context,
            route: NavigationConstants.basketListRoute);
      }
    } else {
      fetchTransferDetails(data.id ?? 0);
      navigate(context, route: NavigationConstants.basketListRoute);
    }
  }

  Future<void> fetchTransferList(BuildContext context) async {
    try {
      transferListLoading = true;
      transferList.clear();
      final url = role?.contains("main") == true
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
        showToast('Failed to fetch transfer list');
      }
    } catch (ex) {
      showToast(ex.toString());
    } finally {
      transferListLoading = false;
      notifyListeners();
    }
  }

  bool scanCountOrder(BuildContext context, int cartItemId) {
    for (var element in selectedTransferModel?.items ?? <TransferItemModel>[]) {
      if (element.product == cartItemId) {
        if (element.itemScanCount == element.quantity) {
          showToast("Item already scanned");
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
              .setMessage(scanMessage);
        }
        notifyListeners();
        return false;
      }
    }
    showToast("Item not found");
    notifyListeners();
    return false;
  }

  Future<bool> scanProduct(
      BuildContext context, int productId, String code) async {
    if (scanTagsList.contains(code)) {
      showToast("Tag already scanned");

      return false;
    }

    final item = selectedTransferModel?.items?.firstWhere(
      (element) => element.product == productId,
      orElse: () => TransferItemModel(),
    );
    if (role?.contains("main") == false) {
      if (item != null && (item.tags?.contains(code) ?? false)) {
        scanTagsList.add(code);
        final scanMessage =
            "Scan ${(item.quantity ?? 0) - item.itemScanCount} more ${item.productName}";
        Provider.of<ScanMessageProvider>(context, listen: false)
            .setMessage(scanMessage);
      } else {
        showToast("Invalid QR ${detectQrMessage(code)}");
        return false;
      }
    } else {
      scanTagsList.add(code);
      final scanMessage =
          "Scan ${(item?.quantity ?? 0) - (item?.itemScanCount ?? 0)} more ${item?.productName}";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(scanMessage);
    }
    final isScanned = scanCountOrder(context, productId);
    if (isScanned) {
      final success = await postScannedTags(context, productId);
      if (success) {
        return true;
      } else {
        removeScanTags(productId);
        item?.itemScanCount = 0;
        showToast("Failed to submit scan tag");
        scanTagsList.clear();
        notifyListeners();
        return false;
      }
    }
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
        removeLoading(context);
        fetchBasketDetails(selectedBasketModel?.identifier ?? "");
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
      fetchBasketDetails(code);
      return true;
    }
    return false;
  }

  // itemTaped
  Future<void> itemTaped(BuildContext context, TransferItemModel? item) async {
    if (item == null) {
      showToast("Item not found");
      return;
    }
    final scanMessage = getScanMessage(item.product ?? 0);
    if (role?.contains("main") == false) {
      if (item.rack != null && item.rack!.isNotEmpty) {
        final result = await navigate(context,
            route: NavigationConstants.scanRackRoute,
            extra: {"rack": item.rack, "productId": item.product});
        if (result == true && context.mounted) {
          Provider.of<ScanMessageProvider>(context, listen: false)
              .setMessage(scanMessage);
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
      showYesNo(context).then((value) {
        if (value == true && context.mounted) {
          navigate(
            context,
            route: NavigationConstants.scanRackRoute,
            extra: {
              "productId": item.product,
            },
          );
          return;
        } else if (context.mounted) {
          Provider.of<ScanMessageProvider>(context, listen: false)
              .setMessage(scanMessage);
          navigate(
            context,
            route: NavigationConstants.productScanScreenRoute,
            extra: {
              "forTransfer": true,
              "productId": item.product,
            },
          );
        }
      });
    } else {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(scanMessage);
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
      final url = role?.contains("main") == true
          ? AppUrls.scanUnitUrl
          : AppUrls.verifyUnitsUrl;
      final urlValue =
          url.replaceAll('id', selectedTransferModel?.id?.toString() ?? '0');
      if (scanTagsList.isEmpty) {
        showToast('No tags to post');
        removeLoading(context);
        return false;
      } else {
        final response = await DioClient().request(
          requestType: RequestType.postWithToken,
          url: urlValue,
          body: {
            "product_id": productId,
            "unit_tags": scanTagsList,
            if (role?.contains("main") == false)
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
          showToast('Failed to post tags');
          removeLoading(context);
          return false;
        }
      }
    } catch (ex) {
      showToast(ex.toString());
      removeLoading(context);
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
        navigateReplacement(
          context,
          route: NavigationConstants.qrScanScreenRoute,
          extra: {
            "forTransfer": true,
            "productId": productId,
          },
        );
        return true;
      } else {
        showToast('Failed to update rack');
        return false;
      }
    } catch (ex) {
      showToast(ex.toString());
      return false;
    }
  }

  // complete transfer
  Future<void> completeTransfer(BuildContext context) async {
    try {
      showLoading(context);
      final id = selectedTransferModel?.id;
      if (id == null) {
        showToast('Transfer ID is null');
        return;
      }
      final url = role?.contains("main") == true
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
        Navigator.pop(context);
      } else {
        showToast('Failed to complete transfer');
      }
    } catch (ex) {
      showToast(ex.toString());
    } finally {
      removeLoading(context);
    }
  }

  fetchBasketDetails(String code) async {
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
      } else {
        showToast('Failed to fetch basket details');
      }
    } catch (ex) {
      showToast(ex.toString());
    } finally {
      selectedTransferModelLoading = false;
      notifyListeners();
    }
  }

  // details
  Future<void> fetchTransferDetails(int id) async {
    try {
      selectedTransferModelLoading = true;
      final url = role?.contains("main") == true
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
        showToast('Failed to fetch transfer details');
      }
    } catch (ex) {
      showToast(ex.toString());
    } finally {
      selectedTransferModelLoading = false;
      notifyListeners();
    }
  }
}
