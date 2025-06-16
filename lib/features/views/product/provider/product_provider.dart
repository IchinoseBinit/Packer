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
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

class ProductProvider extends ChangeNotifier {
  bool isLoading = false;
  List<ProductAvailability> productAvailabilityList = [];

  List<String> scannedUnits = [];

  List<String> rackList = [];

  Map<String, List<ProductAvailability>> rackProductMap = {};

  void initRackProductMap() {
    rackList.clear();
    rackProductMap.clear();
    notifyListeners();
    for (var element in productAvailabilityList) {
      if (!rackList.contains(element.rackName)) {
        rackList.add(element.rackName);
      }

      rackProductMap.putIfAbsent(element.rackName, () => []);
      rackProductMap[element.rackName]!.add(element);
    }

    rackList.sort((a, b) => a.compareTo(b));
    notifyListeners();
  }

  // get count of product scan tags from scannedUnits list
  int getScanCount(int productId) {
    return scannedUnits
        .where((element) => element.split("-").first == productId.toString())
        .length;
  }

  // check if product is scanned
  bool checkScanCount(int productId) {
    final prod = productAvailabilityList
        .firstWhere((element) => element.productId == productId);
    return getScanCount(productId) == prod.productUnits.length;
  }

  // get message
  String getMessage(int productId) {
    final prod = productAvailabilityList
        .firstWhere((element) => element.productId == productId);
    return "Scan ${prod.productUnits.length - getScanCount(productId)} ${prod.productName}";
  }

  void showProductTags(BuildContext context, int productId) {
    // get item
    final item = productAvailabilityList.firstWhereOrNull(
      (element) => element.productId == productId,
    );
    if (item == null) {
      ErrorHandler.alertDialog(context, "Item not found");
      return;
    }
    final remainingTags = getTagsList(productId, true);
    final completedTags = getTagsList(productId, false);
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
  List<String> getTagsList(int productId, bool remaining) {
    final prod = productAvailabilityList
        .firstWhere((element) => element.productId == productId);
    if (remaining) {
      // Return tags that have NOT been scanned
      return prod.productUnits
          .where((tag) => !scannedUnits.contains(tag))
          .toList();
    } else {
      // Return tags that HAVE been scanned
      return prod.productUnits
          .where((tag) => scannedUnits.contains(tag))
          .toList();
    }
  }

  // fetch product availability
  Future<void> fetchProductAvailability(BuildContext context) async {
    try {
      isLoading = true;
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.productAvailabilityUrl,
      );
      if (response.statusCode == 200) {
        productAvailabilityList = (response.data as List)
            .map((e) => ProductAvailability.fromJson(e))
            .toList();
        initRackProductMap();
      } else {
        ErrorHandler.alertDialog(context, "No data found");
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
    } finally {
      isLoading = false;
    }
  }

  onItemTap(BuildContext context, int productId) async {
    // get product
    final prod = productAvailabilityList
        .firstWhereOrNull((element) => element.productId == productId);
    if (prod == null) {
      ErrorHandler.alertDialog(context, "Product not found");
      return;
    }
    bool rackScanned = true;
    if (prod.rackName.isNotEmpty) {
      rackScanned = await navigate(context,
              route: NavigationConstants.scanRackRoute,
              extra: {'rack': prod.rackName}) ??
          false;
    }
    if (rackScanned && context.mounted) {
      navigate(context,
          route: NavigationConstants.productqrScreenRoute,
          extra: {'productId': productId});
    }
  }

  // scanProduct
  Future<bool> scanProduct(
      BuildContext context, int productId, String code) async {
    try {
      final prod = productAvailabilityList
          .firstWhere((element) => element.productId == productId);
      if (scannedUnits.contains(code)) {
        ErrorHandler.alertDialog(context, "Product tag already scanned");
        return false;
      }

      // if code is not in productUnits
      if (!prod.productUnits.contains(code)) {
        ErrorHandler.alertDialog(context, "Product tag not found");
        return false;
      }
      scannedUnits.add(code);
      // check if all tags are scanned of product
      if (checkScanCount(productId)) {
        final success = await postScannedTags(context, productId);
        if (success) {
          return true;
        } else {
          // remove tags of product from scannedUnits
          scannedUnits.removeWhere(
              (element) => element.split("-").first == productId.toString());

          return true;
        }
      } else {
        final scanMessage =
            "Scan ${prod.productUnits.length - getScanCount(productId)} more ${prod.productName}";
        Provider.of<ScanMessageProvider>(context, listen: false)
            .setMessage(context, scanMessage);
        return false;
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
      return false;
    } finally {
      notifyListeners();
    }
  }

  // post scanned tags
  Future<bool> postScannedTags(BuildContext context, int productId) async {
    try {
      showLoading(context);
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.productUnitVerificationUrl,
        body: {
          "product": productId,
          "product_units": getTagsList(productId, false),
        },
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
