import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/extensions/list_extension.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/product/model/product_avaliability.dart';
import 'package:packer/features/views/product/model/unit_verify_model.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

class ProductProvider extends ChangeNotifier {
  List<String> scannedUnits = [];
  List<String> secondaryScannedUnits = [];
  UnitVerifyModel? unitVerifyModel;
  List<ProductAvailability> productAvailabilityList = [];
  List<String> rackList = [];
  Map<String, List<ProductAvailability>> rackMap = {};
  bool isLoading = false;

  // init State
  void initState() {
    unitVerifyModel = UnitVerifyModel(previousRackName: "");
    scannedUnits = [];
    secondaryScannedUnits = [];
  }

  getMessage() {
    if (unitVerifyModel?.productAvailability == null) return "Scan Product code";
    return "Scan ${unitVerifyModel?.productAvailability?.productName}";
  }

  // arrange productAvailabilityList by rack
  void arrangeProductAvailabilityList() {
    rackList.clear();
    rackMap.clear();
    for (var element in productAvailabilityList) {
      if (!rackList.contains(element.rackName)) {
        rackList.add(element.rackName);
      }
      if (rackMap.containsKey(element.rackName)) {
        rackMap[element.rackName]!.add(element);
      } else {
        rackMap[element.rackName] = [element];
      }
    }

    // sort
    rackList.sort((a, b) => a.compareTo(b));
    notifyListeners();
  }

  // fetchProductAvailability
  Future<void> fetchProductAvailability(BuildContext context) async {
    try {
      isLoading = true;
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.productAvailabilityUrl,
      );
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        for (var element in data) {
          productAvailabilityList.add(ProductAvailability.fromJson(element));
        }
        arrangeProductAvailabilityList();
      }
    } catch (e) {
      ErrorHandler.alertDialog(context, e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // check if product is scanned
  bool checkScanCount() {
    // just check len of scannedUnits and unitVerifyModel.productUnitTags
    return scannedUnits.length == secondaryScannedUnits.length;
  }

  void onItemTap(BuildContext context, int? id) {
    initState();
    if (id == null) {
      navigate(context, route: NavigationConstants.unitVerifyScannerRoute);
      return;
    }
    unitVerifyModel = unitVerifyModel?.copyWith(
        product: id,
        productAvailability: productAvailabilityList
            .firstWhere((element) => element.productId == id));
    if (unitVerifyModel?.productAvailability?.rackName.isNotEmpty ?? false) {
      navigate(context, route: NavigationConstants.unitVerifyScannerRoute);
    } else {
      navigate(context, route: NavigationConstants.unitProductScannerRoute);
    }
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
    // log from get tag list
    log("from get tag list: $secondaryScannedUnits $scannedUnits");

    if (remaining) {
      // Tags NOT scanned
      if (secondaryScannedUnits.isEmpty) {
        return scannedUnits;
      }
      return scannedUnits
          .where((tag) => !secondaryScannedUnits.contains(tag))
          .cast<String>()
          .toList();
    } else {
      // Tags scanned
      return scannedUnits
          .where((tag) => secondaryScannedUnits.contains(tag))
          .cast<String>()
          .toList();
    }
  }

  bool checkRackName(String code, {bool first = false}) {
    if (first) {
      return unitVerifyModel?.productAvailability?.rackName
              .contains(unitVerifyModel?.previousRackName ?? '') ??
          false;
    } else {
      return unitVerifyModel?.productAvailability?.rackName
              .contains(unitVerifyModel?.newRackName ?? '') ??
          false;
    }
  }

  // onRackScan
  bool onRackScan(BuildContext context, String code, bool reScan) {
    // debugger();
    bool canNavigate = false;

    if (unitVerifyModel?.productAvailability == null){
      canNavigate = true;
    }else
    if (!reScan) {
      // check with unitVerifyModel
      if (checkRackName(code)) {
        canNavigate = true;
      } else {
        canNavigate = false;
      }
    } else {
      // check with unitVerifyModel
      if (checkRackName(code, first: false)) {
        canNavigate = true;
      } else {
        canNavigate = false;
      }
    }

    // if (unitVerifyModel?.previousRackName.isEmpty ??
    //     true && checkRackName(code, first: true)) {
    //   unitVerifyModel = unitVerifyModel?.copyWith(previousRackName: code);
    // } else if (checkRackName(code, first: false)) {
    //   log("Till now unitVerifyModel: ${unitVerifyModel?.toJson()}");
    //   unitVerifyModel = unitVerifyModel?.copyWith(newRackName: code);
    //   log("After re-scan unitVerifyModel: ${unitVerifyModel?.toJson()}");
    //   // scannedUnits.clear();
    // }

    if (!canNavigate) {
      ErrorHandler.alertDialog(context, "Rack name not matched");
      return false;
    }
    unitVerifyModel = reScan
        ? unitVerifyModel?.copyWith(newRackName: code)
        : unitVerifyModel?.copyWith(previousRackName: code);

    navigateReplacement(
      context,
      route: NavigationConstants.unitProductScannerRoute,
      extra: {
        if (unitVerifyModel?.newRackName != null) 'showInfo': true,
      },
    );
    notifyListeners();
    return true;
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
    // debugger();
    if (scannedUnits.isEmpty && unitVerifyModel?.product == null) {
      // add code to scannedUnits
      // also split id from code
      final id = code.split("-").first;
      final item = productAvailabilityList.firstWhereOrNull((element) => element.productId == int.parse(id));
      if (item == null) {
        ErrorHandler.alertDialog(context, "Product not found");
        return false;
      }
      scannedUnits.add(code);
      unitVerifyModel = unitVerifyModel?.copyWith(product: int.parse(id), productAvailability: item);
    } else {
      // check if code is already in scannedUnits
      if (scannedUnits.contains(code)) {
        ErrorHandler.alertDialog(context, "Product tag already scanned");
        return false;
      } else if (unitVerifyModel?.product.toString() != code.split("-").first) {
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
      navigateReplacement(
        context,
        route: NavigationConstants.unitVerifyScannerRoute,
        extra: {
          'reScan': true,
        },
      );
    // if (unitVerifyModel?.productAvailability?.newRackName.isNotEmpty ?? false) {
    //   final scanMessage = "Scan rack code ${unitVerifyModel?.newRackName ?? ''}";
    // } else {
    //   final scanMessage = "Assign rack code";
    //   Provider.of<ScanMessageProvider>(context, listen: false)
    //       .setMessage(context, scanMessage);
    // }
    final item = productAvailabilityList.firstWhereOrNull((element) => element.productId == unitVerifyModel?.product);
    final scanMessage = (item?.newRackName.isNotEmpty ?? false) ? "Scan rack code ${item?.newRackName}" : "Assign rack code";
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, scanMessage);
    // scannedUnits.clear();
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
    if (secondaryScannedUnits.contains(code)) {
      ErrorHandler.alertDialog(context, "Product tag already scanned");
      return false;
    }
    if (!scannedUnits.contains(code)) {
      ErrorHandler.alertDialog(context, "Product tag not found");
      return false;
    }
    secondaryScannedUnits.add(code);
    

    // check if all tags are scanned of product
    if (checkScanCount()) {
      unitVerifyModel =
          unitVerifyModel?.copyWith(productUnitTags: secondaryScannedUnits);
     return await postScannedTags(context);
      
    }
    final scanMessage = "Scanned ${secondaryScannedUnits.length} tags";
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, scanMessage);
    
    notifyListeners();

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
        productAvailabilityList.removeWhere(
          (element) => element.productId == unitVerifyModel?.product,
        );
        arrangeProductAvailabilityList();
        unitVerifyModel = null;
        showToast('Tags posted successfully');
        notifyListeners();
        removeLoading(context);
        return true;
      } else {
        removeLoading(context);
        ErrorHandler.alertDialog(context, 'Failed to post tags');
        return true;
      }
    } catch (ex) {
      removeLoading(context);
      ErrorHandler.alertDialog(context, ex.toString());
      return true;
    }
  }
}
