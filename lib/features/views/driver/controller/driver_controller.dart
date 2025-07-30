import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/demo.dart';
import 'package:packer/features/views/driver/model/driver_transfer_model.dart';
import 'package:packer/features/views/scanner/model/scan_result.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

class DriverController extends ChangeNotifier {
  List<DriverTransferModel> driverTransfers = [];
  bool isLoading = false;

  List<String> scannedBasketIdentifiers = [];

  DriverTransferModel? selectedModel;

  // onDetails
  void onDetails(BuildContext context, DriverTransferModel transferItem) {
    scannedBasketIdentifiers.clear();
    selectedModel = transferItem;
    navigate(context,
        route: NavigationConstants.driverTransferDetailsRoute,
        extra: {"transferItem" : transferItem});
  }

  void onDetailsFromInTransit(BuildContext context, DriverTransferModel transferItem) {
    scannedBasketIdentifiers.clear();
    selectedModel = transferItem;
    navigate(context,
        route: NavigationConstants.driverTransferDetailsRoute,
        extra: {"transferItem" : transferItem, "fromInTransit" : true});
  }

  bool isBasketScanned(String basketIdentifier) {
    return scannedBasketIdentifiers.contains(basketIdentifier);
  }

  bool isAllBasketScanned() {
    return selectedModel?.basketIdentifiers
            .every((element) => scannedBasketIdentifiers.contains(element)) ??
        false;
  }

  void initializeScan(BuildContext context) {
    if (selectedModel == null) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Basket Identifier");
    } else if (scannedBasketIdentifiers.isEmpty) {
      Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
          context,
          "Scan ${selectedModel?.basketIdentifiers.length} Basket Identifier");
    } else {
      final message =
          "Scan ${(selectedModel?.basketIdentifiers.length ?? 0) - scannedBasketIdentifiers.length} more Basket Identifier";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, message);
    }
  }

  void fetchDriverTransfers(BuildContext context,
      {bool fromBuild = false}) async {
    try {
      isLoading = true;
      driverTransfers.clear();
      if (context.mounted && !fromBuild) {
        notifyListeners();
      }

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.driverScanBasketsUrl,
      );
      final transfers = response.data['transfers'];
      for (var transfer in transfers) {
        driverTransfers.add(DriverTransferModel.fromJson(transfer));
      }
      notifyListeners();
    } catch (ex) {
      log('Error: $ex');
      showToast(ex.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<DriverTransferModel>> getInTransitTransfers() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.driverInTransitTransfersUrl,
      );
      final transfers = response.data['transfers'];
      List<DriverTransferModel> inTransitTransfers = [];
      for (var transfer in transfers) {
        inTransitTransfers.add(DriverTransferModel.fromJson(transfer));
      }
      // List<DriverTransferModel> inTransitTransfers = [];
      // final response = demoData;
      // for (var transfer in response['transfers']) {
      //   inTransitTransfers.add(DriverTransferModel.fromJson(transfer));
      // }
      return inTransitTransfers;
    } catch (ex) {
      log('Error: $ex');
      showToast(ex.toString());
      return [];
    }
  }

  ScanResult onScanBasket(BuildContext context, String code) {
    if (selectedModel == null) {
      return ScanResult(success: false, message: "No transfer selected");
    }
    if (scannedBasketIdentifiers.contains(code)) {
      return ScanResult(success: false, message: "Basket already scanned");
    }
    if (!selectedModel!.basketIdentifiers.contains(code)) {
      return ScanResult(success: false, message: "Invalid basket identifier");
    }
    scannedBasketIdentifiers.add(code);
    if (isAllBasketScanned()) {
      return ScanResult(success: true, message: "All baskets scanned");
    }
    final msg =
        "Scan ${(selectedModel?.basketIdentifiers.length ?? 0) - scannedBasketIdentifiers.length} more Basket Identifier";
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, msg);
    return ScanResult(success: false);
  }

  void completeTransfer(BuildContext context) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
          requestType: RequestType.postWithToken,
          url: AppUrls.driverScanBasketsUrl,
          body: {"basket_identifiers": scannedBasketIdentifiers});
      removeLoading(context);
      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchDriverTransfers(context);
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
