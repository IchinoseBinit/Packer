import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_item_model.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_model.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';

class PackerTransferProvider extends ChangeNotifier {
  var transferList = <TransferModel>[];
  var transferListLoading = false;
  String? scanMessage;
  TransferModel? selectedTransferModel;
  var selectedTransferModelLoading = false;
  String? role;

  List<String> scanTagsList = [];

  void setRole(UserRole value) {
    role = value.name;
  }

  Future<void> fetchTransferList(BuildContext context) async {
    try {
      transferListLoading = true;
      transferList.clear();
      final url = role == "packer"
          ? AppUrls.packerTransferUrl
          : AppUrls.managerTransferUrl;
      final response = await DioClient()
          .request(requestType: RequestType.getWithToken, url: url);
      if (response.statusCode == 200) {
        final data = response.data as List;
        for (var item in data) {
          transferList.add(TransferModel.fromMap(item));
        }
        if (role != "packer" && transferList.isNotEmpty) {
          navigateReplacement(
            context,
            route: NavigationConstants.qrScanScreenRoute,
            extra: {
              "checkIdentifier": true,
              "productId": 0,
            },
          );
          return;
        } else {
          notifyListeners();
        }
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

  // check identifier
  checkIdentifier(
      BuildContext context, MobileScannerController? controller, String code) {
    controller?.stop();

    log(code, name: "qr code data");

    HapticFeedback.heavyImpact();

    showLoading(context);
    for (var element in transferList) {
      if (element.identifier.toString() == code) {
        selectedTransferModel = element;
        scanTagsList.clear();
        notifyListeners();
        removeLoading(context);
        fetchTransferDetails(selectedTransferModel?.id ?? 0);
        navigateReplacement(context,
            route: NavigationConstants.transferDetailsRoute);
        return;
      }
    }
    _handleInvalidQR(context, controller);
  }

  bool scanCountOrder(int cartItemId) {
    for (var element in selectedTransferModel?.items ?? <TransferItemModel>[]) {
      if (element.product == cartItemId) {
        if (element.itemScanCount == element.quantity) {
          showToast("Item already scanned");
          return false;
        }

        element.itemScanCount++;
        if (element.itemScanCount == element.quantity) {
          scanMessage = null;
          showToast("Item scanned successfully");
          notifyListeners();
          return true;
        } else {
          scanMessage =
              "Scan ${(element.quantity ?? 0) - element.itemScanCount} more ${element.productName}";
        }
        notifyListeners();
        return false;
      }
    }
    showToast("Item not found");
    notifyListeners();
    return false;
  }

  checkItemQr(BuildContext context, MobileScannerController? controller,
      String code, int productId) {
    controller?.stop();

    log(code, name: "qr code data");

    HapticFeedback.heavyImpact();

    showLoading(context);

    if (code.contains(productId.toString())) {
      final prodId = int.tryParse(code.split('-').first) ?? 0;
      if (prodId != productId) {
        _handleInvalidQR(context, controller);
        return;
      }

      try {
        if (scanTagsList.contains(code)) {
          removeLoading(context);
          showToast("Tag already scanned");
          controller?.start();
          return;
        }
        if (role != "packer") {
          final item = selectedTransferModel?.items?.firstWhere(
            (element) => element.product == productId,
            orElse: () => TransferItemModel(),
          );
          if (item != null && (item.tags?.contains(code) ?? false)) {
            scanTagsList.add(code);
          } else {
            _handleInvalidQR(context, controller);
            return;
          }
        } else {
          scanTagsList.add(code);
        }
        final isScanned = scanCountOrder(prodId);
        removeLoading(context);
        if (isScanned) {
          postScannedTags(context, productId);
        } else {
          controller?.start();
        }
      } catch (ex) {
        removeLoading(context);
        showToast(ex.toString());
        print(ex.toString());
      }
    } else {
      _handleInvalidQR(context, controller);
    }
  }

  void _handleInvalidQR(
      BuildContext context, MobileScannerController? controller) {
    removeLoading(context);
    ShowAlertDialog(
      body: const Text("Invalid QR"),
      okFunc: () {
        Navigator.pop(context);
        controller?.start();
      },
    ).showAlertDialog(context);
  }

  // post scanned tags
  Future<void> postScannedTags(BuildContext context, int productId) async {
    try {
      showLoading(context);
      final url =
          role == "packer" ? AppUrls.scanUnitUrl : AppUrls.verifyUnitsUrl;
      final urlValue =
          url.replaceAll('id', selectedTransferModel?.id?.toString() ?? '0');
      if (scanTagsList.isEmpty) {
        showToast('No tags to post');
        removeLoading(context);
        navigatePop(context);
      } else {
        final response = await DioClient().request(
          requestType: RequestType.postWithToken,
          url: urlValue,
          body: {
            "product_id": productId,
            "unit_tags": scanTagsList,
          },
        );
        if (response.statusCode == 200) {
          showToast('Tags posted successfully');
          scanTagsList.clear();
          selectedTransferModel?.items?.map((e) {
            if (e.product == productId) {
              e.status = 'packed';
            }
          }).toList();
          removeLoading(context);
          Navigator.pop(context);
        } else {
          showToast('Failed to post tags');
          removeLoading(context);
          navigatePop(context);
        }
      }
    } catch (ex) {
      showToast(ex.toString());
      removeLoading(context);
      navigatePop(context);
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
      final url = role == "packer"
          ? AppUrls.completeTransferUrl
          : AppUrls.acceptTransferUrl;
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url.replaceAll('id', id.toString()),
      );
      if (response.statusCode == 200) {
        showToast('Transfer completed successfully');
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

  // details
  Future<void> fetchTransferDetails(int id) async {
    try {
      selectedTransferModelLoading = true;
      final url = role == "packer"
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
