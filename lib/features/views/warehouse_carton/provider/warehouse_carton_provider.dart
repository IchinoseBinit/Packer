import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/model/carton_model.dart';
import 'package:packer/features/views/scanner/model/scan_result.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/product_tag_sheet.dart';
import 'package:provider/provider.dart';

class WarehouseCartonProvider extends ChangeNotifier {
  // === VARIABLES START ===
  CartonModel? cartonModel; // holds the carton model
  List<String> scannedTags = []; // holds the scanned product tags
  // === VARIABLES END ===

  // === Utils function START ===
  /// sets the message for scanner screen
  void setMessageForScanner(
      BuildContext context, bool forProduct, bool forRack) {
    // if both are false, it means it is called from dashboard
    // so the state variables are reset
    if (!forProduct && !forRack) {
      reset();
    }

    // default Message for scanner screen
    String message = "Scan Carton Code";

    // if carton model is not null and product units is empty
    // so we are in rack assignment/scan state
    if (cartonModel != null && cartonModel!.productUnits.isEmpty) {
      // if rack name is empty, so "assign rack" message
      if (cartonModel!.rackName.isEmpty) {
        message = "Assign Rack for ${cartonModel!.productName}";
      }
      // else "scan rack" message
      else {
        message = "Scan Rack code - ${cartonModel!.rackName}";
      }
    }
    // if carton model is not null and product units is not empty
    // so we are in product scan state
    else if (cartonModel != null && cartonModel!.productUnits.isNotEmpty) {
      // if scanned tags is empty, so it is first scan
      if (scannedTags.isEmpty) {
        message =
            "Scan ${cartonModel!.productUnits.length} ${cartonModel!.productName}";
      }
      // else it is not first scan so subtract scanned tags count from total tags
      else {
        message =
            "Scan ${cartonModel!.productUnits.length - scannedTags.length} ${cartonModel!.productName} more";
      }
    }

    // at last set the message
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }

  // show a dialog which asks for confirmation to assign rack
  //
  // returns true if user clicks ok
  //
  // it is just a formality to ask user to assign rack; it cannot be dismissed
  Future<bool?> showYesNo(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: Text("Assign a rack for ${cartonModel?.productName}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Ok"),
            ),
          ],
        );
      },
    );
  }

  // reset the state variables and notify listeners
  void reset() {
    cartonModel = null;
    scannedTags.clear();
    notifyListeners();
  }

  /// Return TAGS scanned or remaining
  ///
  /// if remaining is true, it returns tags that have NOT been scanned
  /// else it returns tags that have been scanned
  List<String> getTagsRemaining(bool remaining) {
    if (remaining) {
      // Return tags that have NOT been scanned
      return cartonModel?.productUnits
              .where((tag) => !scannedTags.contains(tag))
              .toList() ??
          [];
    } else {
      // Return tags that HAVE been scanned
      return cartonModel?.productUnits
              .where((tag) => scannedTags.contains(tag))
              .toList() ??
          [];
    }
  }

  // show info sheet for product tag
  //
  // we pass remaining tags and completed tags to the sheet
  //
  // remaining tags are tags that have NOT been scanned
  // completed tags are tags that have been scanned
  Future<void> showProductSheet(BuildContext context) async {
    showProductTagSheet(
      context,
      remainingTags: getTagsRemaining(true),
      completedTags: getTagsRemaining(false),
    );
  }

  // === Utils function END ===

  // === Code detect function START ===

  // scan carton code for warehouse
  Future<ScanResult> scanCartonCode(BuildContext context, String code) async {
    try {
      // step 1: check if code is of carton
      // also calls reset because we are starting a new scan
      reset();
      if (!code.contains("carton")) {
        return ScanResult(success: false, message: "Invalid Carton QR");
      }

      // step 2: call api to get carton info and to be assigned to carton model
      await getCartonInfo(context, code);

      // step 3: set message for scanner (true,false) are just for bypass reset
      setMessageForScanner(context, true, false);

      // step 4: check the carton detail and navigate
      if (context.mounted) {
        // if product units is empty for carton model
        // it means we are in rack assignment state
        if (cartonModel!.productUnits.isEmpty) {
          // if rack name is empty, so we need to assign rack
          // ask user to assign rack
          if (cartonModel!.rackName.isEmpty) {
            await showYesNo(context);
          }
          // navigate to scanner screen for updating rack
          navigateReplacement(context,
              route: NavigationConstants.warehouseCartonScannerRoute,
              extra: {
                'forRack': true,
                'rack': cartonModel!.rackName,
              });
        }
        // if product units is not empty for carton model
        // it means we are in product scan state
        else if (cartonModel!.productUnits.isNotEmpty) {
          // navigate to scanner screen for scanning product
          navigateReplacement(context,
              route: NavigationConstants.warehouseCartonScannerRoute,
              extra: {
                'forProduct': true,
                'productId': cartonModel!.productId,
              });
        }
        // if upper conditions are not met, simply go back to dashboard
        else {
          navigatePop(context);
        }
      }

      // step 5: return success for carton code scanned
      return ScanResult(
          success: true, message: "Carton Code Scanned Successfully");
    } catch (e) {
      // catches the exception made during api call
      return ScanResult(success: false, message: e.toString());
    }
  }

  // scan product code for warehouse
  Future<ScanResult> scanProductCode(
      BuildContext context, int productId, String code) async {
    try {
      // step 1: check if code is of product
      if (code.split("-").first != productId.toString()) {
        return ScanResult(success: false, message: "Invalid Product QR");
      }

      // step 2: check if code is already scanned
      if (scannedTags.contains(code)) {
        return ScanResult(success: false, message: "Tag Already scanned");
      }

      // step 3: check if code is from product units
      if (!cartonModel!.productUnits.contains(code)) {
        return ScanResult(success: false, message: "Invalid tag");
      }

      // step 4: add code to scanned tags
      scannedTags.add(code);
      setMessageForScanner(context, true, false);

      // step 5: check if required tags are scanned
      if (scannedTags.length == cartonModel!.productUnits.length) {
        // call api to post and wait for response
        final result = await postCartonProductTags(context);
        // if response is success, navigate to dashboard by upper api call function
        // here it returns success for scanned tags
        if (result) {
          return ScanResult(success: true, message: "Tag scanned successfully");
        }
        // if response is failure, clear scanned tags and return failure
        else {
          scannedTags.clear();
          setMessageForScanner(context, true, false);

          return ScanResult(success: false, message: "Failed to scan tag");
        }
      }

      // if upper conditions are not met,
      // so the more tags are remaing to be scanned that's why it returns false
      // with empty message
      return ScanResult(success: false);
    } catch (e) {
      // catches the exception made during api call
      // clear scanned tags and return failure
      setMessageForScanner(context, true, false);
      scannedTags.clear();
      return ScanResult(success: false, message: e.toString());
    }
  }

  // ==================== API CALLS START ====================
  // get carton info basically from carton identifier
  //
  // carton_info/<str:carton_identifier>/
  //
  // it parse the carton model and set the carton model
  Future<void> getCartonInfo(BuildContext context, String code) async {
    try {
      // step 1: show loading
      showLoading(context);

      // step 2: call api
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.cartonInfoUrl.replaceAll(':id', code),
      );
      debugPrint("Carton Info: ${response.statusCode}");

      // step 3: update carton model
      if (context.mounted) {
        removeLoading(context);
      }
      if (response.statusCode == 200) {
        cartonModel = CartonModel.fromJson(response.data, code);
      }
    } catch (e) {
      // catches the exception made during api call
      if (context.mounted) {
        removeLoading(context);
      }
      rethrow;
    }
  }

  // Post carton product tags
  Future<bool> postCartonProductTags(BuildContext context) async {
    try {
      // step 1: show loading to user
      showLoading(context);
      final url = AppUrls.postCartonProductTagsUrl;

      // step 2: hit api with scanned tags for carton model
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "carton_id": cartonModel!.cartonCode,
          "unit_tags": scannedTags,
        },
      );

      // step 4: remove loading
      if (context.mounted) {
        removeLoading(context);
      }

      // step 5: navigate to dashboard; if respoonse is success; else return false
      if (response.statusCode == 200 && context.mounted) {
        navigatePop(context);
        return true;
      } else {
        return false;
      }
    } catch (ex) {
      // catches the exception made during api call and rethrow
      if (context.mounted) {
        removeLoading(context);
      }
      rethrow;
    }
  }

  /// update rack for the carton
  Future<ScanResult> updateRackForCartonProduct(
      BuildContext context, String code) async {
    try {
      // step 1: show loading to user
      showLoading(context);
      final url = AppUrls.updateRackUrl;

      // step 2: hit api with rack identifier and carton identifier for carton product
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "rack_identifier": code,
          "product_id": cartonModel!.productId,
          if (cartonModel != null) "carton_identifier": cartonModel!.cartonCode,
        },
      );

      // step 3: remove loading
      if (context.mounted) {
        removeLoading(context);
      }

      // step 4: navigate to dashboard; if respoonse is success; else return false
      if (response.statusCode == 200 && context.mounted) {
        navigatePop(context);
        return ScanResult(success: true, message: 'Rack updated successfully');
      } else {
        return ScanResult(success: false, message: 'Failed to update rack');
      }
    } catch (ex) {
      // catches the exception made during api call and returns
      if (context.mounted) {
        removeLoading(context);
      }
      return ScanResult(success: false, message: ex.toString());
    }
  }

  // ==================== API CALLS END =====================
}
