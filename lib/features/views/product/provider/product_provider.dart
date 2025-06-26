import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/product/model/unit_verify_model.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

class ProductProvider extends ChangeNotifier {
  List<String> scannedUnits = [];
  UnitVerifyModel? unitVerifyModel;

  // init State
  void initState() {
    unitVerifyModel = UnitVerifyModel(previousRackName: "");
    scannedUnits = [];
  }

  // check if product is scanned
  bool checkScanCount() {
    // just check len of scannedUnits and unitVerifyModel.productUnitTags
    return scannedUnits.length == unitVerifyModel?.productUnitTags?.length;
  }

  void showProductTags(BuildContext context) {
    // get item

    final remainingTags = getTagsList(true);
    final completedTags = getTagsList(false);
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

  // get tags list of product condition remaining true or false
  List<String> getTagsList(bool remaining) {
    final tags = unitVerifyModel?.productUnitTags ?? [];

    if (remaining) {
      // Tags NOT scanned
      return tags
          .where((tag) => !scannedUnits.contains(tag))
          .cast<String>()
          .toList();
    } else {
      // Tags scanned
      return tags
          .where((tag) => scannedUnits.contains(tag))
          .cast<String>()
          .toList();
    }
  }

  // onRackScan
  void onRackScan(BuildContext context, String code) {
    debugger();
    if (unitVerifyModel == null) {
      log("unitVerifyModel was null, initializing...");
      unitVerifyModel = UnitVerifyModel(
        previousRackName: code,
        productUnitTags: [],
      );
    } else if (unitVerifyModel?.previousRackName.isEmpty ?? true) {
      unitVerifyModel = unitVerifyModel!.copyWith(previousRackName: code);
    } else {
      log("Till now unitVerifyModel: ${unitVerifyModel?.toJson()}");
      unitVerifyModel = unitVerifyModel!.copyWith(newRackName: code);
    }

    navigate(
      context,
      route: NavigationConstants.unitVerifyScannerRoute,
      extra: {
        'productScan': true,
        if (unitVerifyModel?.newRackName != null) 'showInfo': true,
      },
    );
    notifyListeners();
  }

  // scanProduct
  Future<bool> scanProduct(BuildContext context, String code) async {
    try {
      if (unitVerifyModel?.newRackName?.isNotEmpty ?? false) {
        return secondaryTagsScan(context, code);
      }
      return initialTagsScan(context, code);
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
      return false;
    } finally {
      notifyListeners();
    }
  }

  // two types of scan first add tags to scannedUnits and when user press complete then transfer to unitVerifyModel.productUnitTags
  bool initialTagsScan(BuildContext context, String code) {
    if (scannedUnits.isEmpty) {
      // add code to scannedUnits
      scannedUnits.add(code);
      // also split id from code
      final id = code.split("-").first;
      unitVerifyModel = unitVerifyModel?.copyWith(product: int.parse(id));
    } else {
      // check if code is already in scannedUnits
      if (scannedUnits.contains(code)) {
        ErrorHandler.alertDialog(context, "Product tag already scanned");
        return false;
      } else if (scannedUnits.first.split("-").first != code.split("-").first) {
        ErrorHandler.alertDialog(
            context, "Product tag not belongs to same product");
        return false;
      }
      scannedUnits.add(code);
    }
    final scanMessage = "Scanned ${scannedUnits.length} tags";
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, scanMessage);
    notifyListeners();
    return false;
  }

  // complete tags scan
  void completeTagsScan(BuildContext context) {
    unitVerifyModel = unitVerifyModel?.copyWith(productUnitTags: scannedUnits);
    log("on complete tags scan: ${unitVerifyModel?.toJson()}");
    scannedUnits.clear();
    // notifyListeners();
  }

  // secondary scan
  Future<bool> secondaryTagsScan(BuildContext context, String code) async {
    // now we only have to check for unitVerifyModel.productUnitTags if contain then add to scannedUnits
    // also check if code is not in scannedUnits
    // also check if code is not in unitVerifyModel.productUnitTags
    // check with unitVerifyModel.product
    if (unitVerifyModel?.product != int.tryParse(code.split("-").first)) {
      ErrorHandler.alertDialog(
          context, "Product tag not belongs to same product");
      return false;
    }
    if (scannedUnits.contains(code)) {
      ErrorHandler.alertDialog(context, "Product tag already scanned");
      return false;
    }
    if (unitVerifyModel?.productUnitTags?.contains(code) ?? false) {
      scannedUnits.add(code);

      // check if all tags are scanned of product
      if (checkScanCount()) {
        await postScannedTags(context);
        unitVerifyModel = null;
        return true;
      }
      final scanMessage = "Scanned ${scannedUnits.length} tags";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, scanMessage);
      notifyListeners();
    }
    return false;
  }

  // post scanned tags
  Future<bool> postScannedTags(BuildContext context) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.productUnitVerificationUrl,
        body: unitVerifyModel?.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        showToast('Tags posted successfully');
        notifyListeners();
        removeLoading(context);
        return true;
      } else {
        removeLoading(context);
        ErrorHandler.alertDialog(context, 'Failed to post tags');
        return false;
      }
    } catch (ex) {
      removeLoading(context);
      ErrorHandler.alertDialog(context, ex.toString());
      return false;
    }
  }
}
