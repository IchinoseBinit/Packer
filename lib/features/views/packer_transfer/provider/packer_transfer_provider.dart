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
import 'package:packer/features/views/packer_transfer/model/basket_model.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_item_model.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_model.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
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

  void setRole(UserRole value) {
    role = value.name;
  }

  void initScanMessage(int id) {
    for (var element in selectedTransferModel?.items ?? <TransferItemModel>[]) {
      if (element.product == id) {
        print("init scan message if");
        scanMessage =
            "Scan ${(element.quantity ?? 0) - element.itemScanCount} ${element.productName}";
        notifyListeners();
        return;
      }
    }
    scanMessage = null;
    notifyListeners();
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

  void onDetailsTaped(BuildContext context, TransferModel data) {
    if (role != "packer") {
      selectedTransferModel = data;
      navigate(
        context,
        route: NavigationConstants.qrScanScreenRoute,
        extra: {
          "checkIdentifier": true,
          "productId": data.id ?? 0,
        },
      );
      return;
    }
    fetchTransferDetails(data.id ?? 0);
    navigate(context, route: NavigationConstants.transferDetailsRoute);
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
        // if (role != "packer" && transferList.isNotEmpty) {
        //   navigateReplacement(
        //     context,
        //     route: NavigationConstants.qrScanScreenRoute,
        //     extra: {
        //       "checkIdentifier": true,
        //       "productId": 0,
        //     },
        //   );
        //   return;
        // } else {
        notifyListeners();
        // }
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

    if (selectedTransferModel?.identifier.toString() == code) {
      scanTagsList.clear();
      notifyListeners();
      removeLoading(context);
      fetchTransferDetails(selectedTransferModel?.id ?? 0);
      navigateReplacement(context, route: NavigationConstants.basketListRoute);
      return;
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

  onBasketScanTapped(BuildContext context, BasketModel basket) {
    selectedBasketModel = basket;
    notifyListeners();
    navigate(context, route: NavigationConstants.qrScanScreenRoute, extra: {
      "forBasket": true,
      "message": "Scan Basket",
    });
  }

  checkBasketQr(
      BuildContext context, MobileScannerController? controller, String code) {
    controller?.stop();

    log(code, name: "qr code data");

    HapticFeedback.heavyImpact();

    showLoading(context);

    if (selectedBasketModel?.identifier
            .toLowerCase()
            .contains(code.toLowerCase()) ??
        false) {
      scanTagsList.clear();
      notifyListeners();
      removeLoading(context);
      fetchBasketDetails(code);
      navigateReplacement(context,
          route: NavigationConstants.transferDetailsRoute);
      return;
    }
    _handleInvalidQR(context, controller);
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

  // itemTaped
  void itemTaped(BuildContext context, TransferItemModel? item) {
    if (item == null) {
      showToast("Item not found");
      return;
    }
    if (role == "manager") {
      if (item.rack != null && item.rack!.isNotEmpty) {
        navigate(context,
            route: NavigationConstants.scanRackRoute,
            extra: {"rack": item.rack, "productId": item.product});
        return;
      }
       showYesNo(context).then((value) {
        if (value == true) {
          navigate(
            context,
            route: NavigationConstants.scanRackRoute,
            extra: {
              "updateRack": true,
              "productId": item.product,
              'message': '${item.productName} - Assign a Rack'
            },
          );
          return;
        } else {
          initScanMessage(item.product ?? 0);
          navigate(
            context,
            route: NavigationConstants.qrScanScreenRoute,
            extra: {
              "forTranfer": true,
              "productId": item.product,
            },
          );
        }
      });
    } else {
      initScanMessage(item.product ?? 0);
      navigate(
        context,
        route: NavigationConstants.qrScanScreenRoute,
        extra: {
          "forTranfer": true,
          "productId": item.product,
        },
      );
    }
  }

  // show yes no for update product rack
  Future<bool?> showYesNo(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: const Text("Do you want to assign a rack?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
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
            if (role != "packer")
              "basket_identifier": selectedBasketModel?.identifier,
          },
        );
        if (response.statusCode == 200) {
          showToast('Tags posted successfully');
          scanTagsList.clear();
          notifyListeners();
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

  Future<void> updateRack(BuildContext context, String code, int productId) async {
    try {
      showLoading(context);
      final url = AppUrls.updateRackUrl;
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "rack_identifier": code,
          "product_id": productId,
          // "store_id": "selectedTransferModel?.storeId",
        },
      );
      removeLoading(context);
      if (response.statusCode == 200) {
        for (var element
            in selectedTransferModel?.items ?? <TransferItemModel>[]) {
          if (element.product == productId) {
            element.rack = code;
          }
        }
        Provider.of<PackerTransferProvider>(context, listen: false)
            .initScanMessage(productId);
        navigateReplacement(context,
            route: NavigationConstants.qrScanScreenRoute,
            extra: {
              "forTranfer": true,
              "productId": productId,
            });
      } else {
        showToast('Failed to update rack');
      }
    } catch (ex) {
      showToast(ex.toString());
      removeLoading(context);
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
