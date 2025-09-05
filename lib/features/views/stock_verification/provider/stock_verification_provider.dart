import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/scanner/model/scan_result.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/stock_verification/model/store_model.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

class StockVerificationProvider extends ChangeNotifier {
  bool isLoading = false;

  List<Store> storeList = [];
  Store? selectedStore;

  List<String> scannedUnits = [];

  String scannedRackCode = "";
  String cartonId = "";
  int auditId = 0;

  /// ==================== Utility Functions START =====================

  // show change rack button
  bool showChangeRackButton() {
    final mainStore = selectedStore?.isMainStore ?? false;
    // if main store and carton id is empty
    if (mainStore && cartonId.isEmpty) {
      return true;
    }
    // if not main store and scanned units is empty
    if (!mainStore && scannedUnits.isEmpty) {
      return true;
    }
    return false;
  }

  // show complete button
  bool showCompleteButton() {
    // if scanned units is not empty
    if (scannedUnits.isNotEmpty) {
      return true;
    }
    return false;
  }

  // reset : clear scanned units, scanned rack code, carton id
  void reset() {
    scannedUnits.clear();
    scannedRackCode = "";
    cartonId = "";
    notifyListeners();
  }

  // setScanMessage : set scan message based on scanned units and rack code
  // if scanned rack code is empty, show "Scan Rack Code"
  // if main store and carton id is empty, show "Scan Carton Code"
  // if not main store and scanned units is not empty, show "Scan Product Code"
  // else show "Scan Product Code - ${scannedUnits.length} units scanned"
  void setScanMessage(BuildContext context) {
    var message = "Scan Rack Code";
    if (scannedRackCode.isEmpty) {
      message = "Scan Rack Code";
    } else if ((selectedStore?.isMainStore ?? false) && cartonId.isEmpty) {
      message = "Scan Carton Code";
    } else if (scannedUnits.isEmpty) {
      message = "Scan Product Code";
    } else {
      message = "Scan Product Code - ${scannedUnits.length} units scanned";
    }
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }

  /// ==================== Utility Functions END =====================
  

  /// ==================== CODE DETECTION LOGIC START HERE ================

  /// [onRackScan] : scan rack code
  ///
  /// starts with scanning rack code
  /// assign code to variable
  ///
  /// if main store; navigate to carton scan screen
  /// else navigate to product scan screen
  ScanResult onRackScan(BuildContext context, String code) {
    try {
      // step 1: assign code to scannedRackCode
      scannedRackCode = code;
      // step 2: clear scannedUnits
      scannedUnits.clear();
      // step 3: set scan message
      setScanMessage(context);

      // step 4: navigate to next screen
      if (selectedStore?.isMainStore ?? false) {
        navigateReplacement(context,
            route: NavigationConstants.stockVerificationScannerRoute,
            extra: {
              'forCarton': true,
            });
      } else {
        navigateReplacement(context,
            route: NavigationConstants.stockVerificationScannerRoute,
            extra: {
              'forProduct': true,
            });
      }
      // step 5: return success
      return ScanResult(success: true, message: "Rack Scanned Successfully");
    } catch (e) {
      // if error, return failure
      return ScanResult(success: false, message: e.toString());
    }
  }

  // onScanProduct
  ScanResult onScanProduct(BuildContext context, String code) {
    // step 1: check if main store and then check if product carton id matches carton id
    if (selectedStore?.isMainStore ?? false) {
      final productCartonId = code.split("-")[2];
      if (productCartonId != cartonId) {
        return ScanResult(
            success: false, message: "Product does not match carton");
      }
    }
    // step 2: check if scannedUnits is empty; if yes, add code to scannedUnits
    if (scannedUnits.isEmpty) {
      scannedUnits.add(code);
    } 
    // else; check if scannedUnits contains code; if yes, return failure
    else if (scannedUnits.contains(code)) {
      return ScanResult(success: false, message: "Tag Already scanned");
    } 
    // else; scanned unit first tag split .first is same as code split .first
    else {
      // check if scanned unit first tag split .first is same as code split .first
      final scannedUnitFirstTag = scannedUnits.first.split('-').first;
      final codeFirstTag = code.split('-').first;
      // if not same, return failure
      if (scannedUnitFirstTag != codeFirstTag) {
        return ScanResult(success: false, message: "Product does not match");
      }
      // if same, add code to scannedUnits
      scannedUnits.add(code);
    }
    // step 3: set scan message
    setScanMessage(context);
    notifyListeners();
    // step 4: return success
    return ScanResult(success: false);
  }

  /// =================== CODE DETECTION LOGIC END HERE ===================

  /// =================== API CALLS START HERE ===================
  ///

  // store selection screen : fetch stores and display in list
  Future<void> fetchStores() async {
    try {
      
      // step 1: fetch stores
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.getStoreUrl,
      );
      // step 2: assign response to storeList
      storeList =
          (response.data as List).map((e) => Store.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      // if error, log error
      log("Error while getting value $e");
      notifyListeners();
    }
  }

  // call from store_selection_screen :: start audit
  void setSelectedStore(BuildContext context, Store store) async {
    // step 1: set selected store and reset
    selectedStore = store;
    auditId = 0;
    reset();
    try {
      // step 2: show loading
      showLoading(context);
      // step 3: call api
      final apiResponse = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.getAuditViewUrl,
        body: {
          "store_id": store.id,
        },
      );
      // step 4: check response
      if (context.mounted) {
        removeLoading(context);
        // step 5: check response if not 200 then show error dialog
        if (apiResponse.statusCode != 200) {
          ErrorHandler.alertDialog(context, 'Failed to get audit view');
          return;
        }
        // step 6: assign audit id
        auditId = apiResponse.data['audit_id'].toString().toInt();
        navigate(
          context,
          route: NavigationConstants.stockVerificationScannerRoute,
        );
        // step 7: set scan message
        setScanMessage(context);
      }
    } catch (e) {
      // if error, handle error
      if (context.mounted) {
        removeLoading(context);
        ErrorHandler.alertDialog(context, e.toString());
      }
      log("Error while getting audit view $e");
    }
  }

  /// [setCartonId] : set carton id if selected store is main store
  /// 
  /// if selected store is main store, then set carton id
  /// scans carton code and fetches carton id from api
  /// 
  Future<ScanResult> setCartonId(
      BuildContext context, String identifier) async {
    try {
      // step 1: show loading
      showLoading(context);
      // step 2: create url
      final url = AppUrls.cartonByIdentifierUrl
          .replaceFirst(':identifier', identifier.toString());
      // step 3: call api
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );
      // step 4: remove loading
      if (context.mounted) {
        removeLoading(context);
      }
      // step 5: check response; if not 200 then return failure; else set carton id & set message
      if (response.statusCode == 200) {
        cartonId = response.data['id'].toString();
        if (context.mounted) {
          setScanMessage(context);
        }
        return ScanResult(success: true, message: 'Carton Detail Found');
      }
      return ScanResult(success: false, message: 'Failed to get carton info');
    } catch (e) {
      if (context.mounted) {
        removeLoading(context);
      }
      return ScanResult(success: false, message: e.toString());
    }
  }

  // This should only be called when the button on the ui is clicked.
  // The button would only be visible when the scanned units are equal to the product units.
  // The person can scan other units as well but the button would not be visible.
  Future<ScanResult> onVerify(BuildContext context) async {
    try {
      // step 1: show loading
      showLoading(context);
      // step 2: call api
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.stockVerificationUrl,
        body: {
          "product": scannedUnits.first.split('-').first,
          "product_units": scannedUnits,
          "audit_id": auditId,
          "rack_id": scannedRackCode,
          if (selectedStore?.isMainStore ?? false) "carton_id": cartonId,
        },
      );
      // step 3: remove loading
      if (context.mounted) {
        removeLoading(context);
      }
      // step 4: check response; if success then clear scanned units & carton id & set message
      if (response.statusCode == 200 || response.statusCode == 201) {
        scannedUnits.clear();
        if (selectedStore?.isMainStore ?? false) {
          cartonId = "";
        }
        if (context.mounted) {
          setScanMessage(context);
        }
        notifyListeners();
        return ScanResult(success: true, message: "Verification successful");
      }
      // step 5: if failure then clear scanned units & carton id & set message & return failure
      scannedUnits.clear();
      if (context.mounted) {
        setScanMessage(context);
      }
      notifyListeners();
      return ScanResult(success: false, message: "Verification failed");
    } catch (e) {
      // if errror occurs then clear scanned units & carton id & set message & return failure with error message
      scannedUnits.clear();
      if (context.mounted) {
        removeLoading(context);
        setScanMessage(context);
      }
      notifyListeners();
      return ScanResult(success: false, message: e.toString());
    }
  }

  /// =================== API CALLS END HERE ===================
}
