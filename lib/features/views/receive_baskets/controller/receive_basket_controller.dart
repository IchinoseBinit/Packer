import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/demo.dart';
import 'package:packer/features/views/receive_baskets/model/receive_basket_model.dart';
import 'package:packer/features/views/scanner/model/scan_result.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

class ReceiveBasketController extends ChangeNotifier {
  bool isLoading = false;
  List<ReceiveBasketModel> receiveBasketList = [];

  List<String> scannedTags = [];
  ReceiveBasketModel? selectedTransfer;

  void getReceiveBasketList(BuildContext context,
      {bool isFromBuild = false}) async {
    try {
      isLoading = true;
      receiveBasketList.clear();
      if (context.mounted && !isFromBuild) {
        notifyListeners();
      }
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.managerInTransitTransfersUrl,
      );

      final transfers = response.data['transfers'];
      // final transfers = demoData['transfers']; ///// for test UI
      for (var transfer in transfers) {
        receiveBasketList.add(ReceiveBasketModel.fromJson(transfer));
      }
      notifyListeners();
    } catch (e) {
      log('Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // onDetailsTap
  void onDetailsTap(BuildContext context, ReceiveBasketModel transferItem) {
    selectedTransfer = transferItem;
    scannedTags.clear();
    navigate(context,
        route: NavigationConstants.receiveBasketScannerRoute,
        extra: {"scanIdentifier": true});
  }

  // onScanIdentifier
  ScanResult onScanIdentifier(BuildContext context, String code) {
    if (selectedTransfer == null) {
      return ScanResult(success: false, message: "No transfer selected");
    }
    if (code.contains(selectedTransfer?.transferIdentifier ?? '')) {
      return ScanResult(success: true, message: "Transfer Identifier Scanned");
    }
    return ScanResult(success: false, message: "Invalid Transfer Identifier");
  }

  bool isBasketScanned(String basketIdentifier) {
    return scannedTags.contains(basketIdentifier);
  }

  bool isAllBasketScanned() {
    return selectedTransfer?.basketIdentifiers
            .every((element) => scannedTags.contains(element)) ??
        false;
  }

  ScanResult onScanBasket(BuildContext context, String code) {
    if (selectedTransfer == null) {
      return ScanResult(success: false, message: "No transfer selected");
    }
    if (scannedTags.contains(code)) {
      return ScanResult(success: false, message: "Basket already scanned");
    }
    if (!selectedTransfer!.basketIdentifiers.contains(code)) {
      return ScanResult(success: false, message: "Invalid basket identifier");
    }
    scannedTags.add(code);
    if (isAllBasketScanned()) {
      return ScanResult(success: true, message: "All baskets scanned");
    }
    final msg =
        "Scan ${(selectedTransfer?.basketIdentifiers.length ?? 0) - scannedTags.length} more Basket Identifier";
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, msg);
    return ScanResult(success: false);
  }

  void getMessageForBasket(BuildContext context) {
    if (selectedTransfer == null) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Basket Identifier");
    } else if (scannedTags.isEmpty) {
      Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
          context,
          "Scan ${selectedTransfer?.basketIdentifiers.length} Basket Identifier");
    } else {
      final message =
          "Scan ${(selectedTransfer?.basketIdentifiers.length ?? 0) - scannedTags.length} more Basket Identifier";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, message);
    }
  }

  void getMessageForIdentifier(BuildContext context) {
    if (selectedTransfer == null) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Transfer Identifier");
    } else {
      final message =
          "Scan Identifier - ${selectedTransfer?.transferIdentifier}";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, message);
    }
  }

  void completeTransfer(BuildContext context) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
          requestType: RequestType.postWithToken,
          url: AppUrls.managerReceiveTransferUrl.replaceAll(
              ":id", selectedTransfer?.transferId.toString() ?? ""),
          body: {"basket_identifiers": scannedTags});
      removeLoading(context);
      if (response.statusCode == 200 || response.statusCode == 201) {
        getReceiveBasketList(context);
        showToast("Transfer completed successfully");
        navigateAndRemoveAll(context,
            route: NavigationConstants.dashboardRoute);
      } else {
        showToast("Failed to complete transfer");
      }
    } catch (ex) {
      log('Error: $ex');
      removeLoading(context);
      showToast(ex.toString());
    }
  }
}
