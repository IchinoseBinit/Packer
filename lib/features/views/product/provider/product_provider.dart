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
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';

class ProductProvider extends ChangeNotifier {
  // Constants
  // static const int maxProductCount = 2;

  // State variables
  List<String> scannedUnits = [];
  List<String> secondaryScannedUnits = [];
  List<UnitVerifyModel> unitVerifyModels = [];
  UnitVerifyModel? unitVerifyModel;
  List<ProductAvailability> productAvailabilityList = [];
  List<String> rackList = [];
  Map<String, List<ProductAvailability>> rackMap = {};
  bool isLoading = false;
  int currentIndex = 0;

  // Initialize state
  void resetState() {
    unitVerifyModel ??= UnitVerifyModel(previousRackName: "");
    // scannedUnits.clear();
    // unitVerifyModels.clear();
    // secondaryScannedUnits.clear();
    // currentIndex = 0;
    notifyListeners();
  }

  bool canScanNewProduct() {
    return (unitVerifyModel?.productCount ?? 0) ==
        getScannedUnitsForProduct().length;
  }

  List<String> getScannedUnitsForProduct() {
    return scannedUnits.where((tag) {
      final isSameProduct =
          tag.split("-").first == unitVerifyModel?.product?.toString();
      return isSameProduct;
    }).toList();
  }

  String getScanMessage({bool isVerificationScan = false}) {
    if (!isVerificationScan && canScanNewProduct()) {
      return "Scan new product";
    }
    if (isVerificationScan) {
      return unitVerifyModel?.productAvailability == null
          ? "Scan Product code"
          : "Scan ${unitVerifyModel?.productCount} ${unitVerifyModel?.productAvailability?.productName} \n Rack Name: ${unitVerifyModel?.newRackName}";
    }
    return unitVerifyModel?.productAvailability == null
        ? "Scan Product code"
        : "Scan ${unitVerifyModel?.productAvailability?.productName}";
  }

  // Organize products by rack
  void organizeProductsByRack() {
    rackList.clear();
    rackMap.clear();

    for (final product in productAvailabilityList) {
      if (!rackList.contains(product.rackName)) {
        rackList.add(product.rackName);
      }
      rackMap.putIfAbsent(product.rackName, () => []).add(product);
    }

    rackList.sort((a, b) => a.compareTo(b));
    notifyListeners();
  }

  // Fetch product availability data
  Future<void> fetchProductAvailability(BuildContext context) async {
    try {
      if (productAvailabilityList.isNotEmpty) {
        return;
      }
      isLoading = true;
      notifyListeners();

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.productAvailabilityUrl,
      );

      if (response.statusCode == 200) {
        productAvailabilityList = (response.data as List)
            .map((e) => ProductAvailability.fromJson(e))
            .toList();
        organizeProductsByRack();
      }
    } catch (e) {
      ErrorHandler.alertDialog(context, e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool hasCompletedScanning() {
    return scannedUnits.length == secondaryScannedUnits.length;
  }

  void navigateToProductScanner(BuildContext context, int? productId) {
    resetState();

    if (productId == null) {
      navigate(context, route: NavigationConstants.unitProductScannerRoute);
      return;
    }

    unitVerifyModel = unitVerifyModel?.copyWith(
      product: productId,
      productAvailability: productAvailabilityList
          .firstWhere((element) => element.productId == productId),
    );

    navigate(context, route: NavigationConstants.unitProductScannerRoute);
  }

  void showProductTagsDialog(BuildContext context) {
    final remainingTags = _getTagsList(remaining: true);
    final completedTags = _getTagsList(remaining: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _buildTagsDialogContent(context, remainingTags, completedTags),
    );
  }

  Widget _buildTagsDialogContent(BuildContext context,
      List<String> remainingTags, List<String> completedTags) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text("Product Tags")),
          SizedBox(height: 12.h),
          if (remainingTags.isNotEmpty) ...[
            _buildTagsSection(context, "Remaining Tags", remainingTags,
                isCompleted: false),
          ],
          if (completedTags.isNotEmpty) ...[
            _buildTagsSection(context, "Completed Tags", completedTags,
                isCompleted: true),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsSection(
      BuildContext context, String title, List<String> tags,
      {required bool isCompleted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        SizedBox(height: 12.h),
        ListView.separated(
          shrinkWrap: true,
          itemCount: tags.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) => isCompleted
              ? _buildCompletedTagItem(context, tags[index])
              : Text(tags[index],
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 13.sp)),
        ),
      ],
    );
  }

  Widget _buildCompletedTagItem(BuildContext context, String tag) {
    return Row(
      children: [
        Expanded(
          child: Text(
            tag,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green,
                  fontSize: 13.sp,
                ),
          ),
        ),
        const Icon(Icons.check_circle, color: Colors.green),
      ],
    );
  }

  List<String> _getTagsList({required bool remaining}) {
    final productId = unitVerifyModel?.product?.toString();
    if (productId == null) return [];

    return scannedUnits.where((tag) {
      final isSameProduct = tag.split("-").first == productId;
      return remaining
          ? isSameProduct && !secondaryScannedUnits.contains(tag)
          : isSameProduct && secondaryScannedUnits.contains(tag);
    }).toList();
  }

  bool isRackNameValid(String code, {bool isFirstScan = false}) {
    final rackName = isFirstScan
        ? unitVerifyModel?.productAvailability?.rackName
        : unitVerifyModel?.productAvailability?.newRackName;

    return code.contains(rackName ?? '');
  }

  bool handleRackScan(BuildContext context, String code, bool isRescan) {
    final isValidRack = isRackNameValid(code, isFirstScan: !isRescan);

    if (!isValidRack) {
      ErrorHandler.alertDialog(context, "Rack name not matched");
      return false;
    }

    unitVerifyModel = isRescan
        ? unitVerifyModel?.copyWith(newRackName: code)
        : unitVerifyModel?.copyWith(previousRackName: code);

    if (isRescan) {
      unitVerifyModels[currentIndex] = unitVerifyModel!;
    }

    navigateReplacement(
      context,
      route: NavigationConstants.unitProductScannerRoute,
      extra: {'showInfo': unitVerifyModel?.newRackName != null},
    );

    notifyListeners();
    return true;
  }

  void switchToNextProduct(BuildContext context) {
    // if (unitVerifyModels.length >= maxProductCount) {
    //   ErrorHandler.alertDialog(
    //     context,
    //     "You can only scan $maxProductCount products of same rack",
    //   );
    //   return;
    // }

    unitVerifyModels.add(unitVerifyModel!.copyWith(
      productUnitTags: _getCurrentProductTags(),
    ));

    unitVerifyModel = UnitVerifyModel(
      previousRackName: unitVerifyModel?.previousRackName ?? '',
    );

    _updateScanMessage(context, "Scan new product");
  }

  List<String> _getCurrentProductTags() {
    final productId = unitVerifyModel?.product?.toString();
    return productId == null
        ? []
        : scannedUnits.where((e) => e.split("-").first == productId).toList();
  }

  Future<bool> handleProductScan(BuildContext context, String code) async {
    try {
      return unitVerifyModel?.newRackName?.isNotEmpty ?? false
          ? _handleSecondaryScan(context, code)
          : _handleInitialScan(context, code);
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> _handleInitialScan(BuildContext context, String code) async {
    if (unitVerifyModel?.product == null) {
      return _processNewProductScan(context, code);
    }

    return _processExistingProductScan(context, code);
  }

  bool _processNewProductScan(BuildContext context, String code) {
    // check if product is already scanned
    if (scannedUnits.contains(code)) {
      ErrorHandler.alertDialog(context, "Product tag already scanned");
      return false;
    }

    final id = code.split("-").first;
    final product = productAvailabilityList.firstWhereOrNull(
      (e) => e.productId == int.tryParse(id),
    );

    // also check does this product is in unitVerifyModels
    if (unitVerifyModels.any((e) => e.product == int.parse(id))) {
      final product = productAvailabilityList.firstWhereOrNull(
        (e) => e.productId == int.tryParse(id),
      );
      final scanCount =
          scannedUnits.where((e) => e.split("-").first == id).length;
      ErrorHandler.alertDialog(
          context, "Product ${product?.productName} scanned : $scanCount");
      return false;
    }

    if (product == null) {
      ErrorHandler.alertDialog(context, "Product not found");
      return false;
    }

    scannedUnits.add(code);
    unitVerifyModel = unitVerifyModel?.copyWith(
        product: int.parse(id),
        productAvailability: product,
        productUnitTags: product.productUnits);

    _updateScanMessage(
        context, canScanNewProduct() ? "Scan new product" : null);
    if (canScanNewProduct()) {
      switchToNextProduct(context);
    }
    return false;
  }

  bool _processExistingProductScan(BuildContext context, String code) {
    if (scannedUnits.contains(code)) {
      ErrorHandler.alertDialog(context, "Product tag already scanned");
      return false;
    }

    if (unitVerifyModel?.product.toString() != code.split("-").first) {
      ErrorHandler.alertDialog(
          context, "Product tag not belongs to this product");
      return false;
    }

    scannedUnits.add(code);
    _updateScanMessage(
        context, canScanNewProduct() ? "Scan new product" : null);
    if (canScanNewProduct()) {
      switchToNextProduct(context);
    }
    return false;
  }

  void _updateScanMessage(BuildContext context, [String? customMessage]) {
    final message = customMessage ?? _generateScanMessage();
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }

  void _updateScanMessage2(BuildContext context, [String? customMessage]) {
    final message = customMessage ?? _generateScanMessage2();
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }

  String _generateScanMessage() {
    final scannedCount = _getCurrentProductTags().length;
    return "Scanned $scannedCount ${unitVerifyModel?.productAvailability?.productName}";
  }

  String _generateScanMessage2() {
    final scannedCount = _getCurrentProductTags().length;
    final remainingCount = scannedCount -
        secondaryScannedUnits
            .where((e) =>
                e.split("-").first == unitVerifyModel?.product.toString())
            .length;
    return "Scan $remainingCount ${unitVerifyModel?.productAvailability?.productName} more \n Rack Name: ${unitVerifyModel?.newRackName}";
  }

  void completeScanningSession(BuildContext context, {bool repeat = false}) {
    if (unitVerifyModel?.product != null) {
      unitVerifyModels.add(unitVerifyModel!.copyWith(
        productUnitTags: _getCurrentProductTags(),
      ));
    }

    _logScanningSession();

    navigateReplacement(
      context,
      route: NavigationConstants.unitVerifyScannerRoute,
      extra: {'reScan': true},
    );

    if (repeat) {
      currentIndex++;
    } else {
      currentIndex = 0;
      _sortUnitVerifyModels();
    }

    unitVerifyModel = unitVerifyModels[currentIndex];
    _updateScanMessage(context, _generateRackScanMessage());
  }

  void _logScanningSession() {
    for (final model in unitVerifyModels) {
      log("Scanning session: ${model.toJson()}");
    }
  }

  void _sortUnitVerifyModels() {
    unitVerifyModels.sort(
      (a, b) => (a.productAvailability?.newRackName ?? '')
          .compareTo(b.productAvailability?.newRackName ?? ''),
    );
  }

  String _generateRackScanMessage() {
    final rackName = unitVerifyModel?.productAvailability?.newRackName;
    final productName = unitVerifyModel?.productAvailability?.productName;

    return rackName?.isNotEmpty ?? false
        ? "Scan rack code $rackName"
        : "Assign new rack code for $productName";
  }

  Future<bool> _handleSecondaryScan(BuildContext context, String code) async {
    if (!_validateSecondaryScan(code, context)) {
      return false;
    }

    secondaryScannedUnits.add(code);

    // if (hasCompletedScanning()) {
    //   await _processCompletedScan(context);
    //   return true;
    // }

    return await _handlePartialScanCompletion(context);
  }

  bool _validateSecondaryScan(String code, BuildContext context) {
    if (unitVerifyModel?.product.toString() != code.split("-").first) {
      ErrorHandler.alertDialog(
          context, "Product tag not belongs to this product");
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

    return true;
  }

  Future<void> _processCompletedScan(BuildContext context) async {
    for (final model in unitVerifyModels) {
      unitVerifyModel = model;
      final result = await postScannedTags(context);
      if (result && unitVerifyModels.isEmpty) navigatePop(context);
    }

    unitVerifyModel = null;
  }

  Future<bool> _handlePartialScanCompletion(BuildContext context) async {
    _updateScanMessage2(context);

    final scannedCount = _getCurrentProductTags().length;
    final initialCount = secondaryScannedUnits
        .where((e) => e.split("-").first == unitVerifyModel?.product.toString())
        .length;

    if (scannedCount == initialCount) {
      await postScannedTags(context);
      await Future.delayed(const Duration(seconds: 1));
      final shouldPickUp = await showPickUpRerackDialog(context);
      await _handleScanCompletionDecision(context, shouldPickUp);
    }

    notifyListeners();
    return false;
  }

  Future<bool?> showPickUpRerackDialog(BuildContext context) {
    return ShowAlertDialog(
      body: const Text("You have scanned tags for this product."),
      needCancel: scannedUnits.isNotEmpty,
      disableBackground: true,
      canDismiss: true,
      okTitle: "Pick Up",
      cancelTitle: "Re-rack",
      okFunc: () => Navigator.pop(context, true),
      cancelFunc: () => Navigator.pop(context, false),
    ).showAlertDialog(context);
  }

  Future<void> _handleScanCompletionDecision(
      BuildContext context, bool? shouldPickUp) async {
    if (shouldPickUp == null) return;

    if (shouldPickUp) {
      await Future.delayed(const Duration(seconds: 1));
      unitVerifyModel = UnitVerifyModel(previousRackName: '');
      // resetState();
      _updateScanMessage(context, "Scan product code");
      navigateReplacement(context,
          route: NavigationConstants.unitProductScannerRoute);
    } else {
      completeScanningSession(context, repeat: true);
    }

    await Future.delayed(const Duration(seconds: 1));
  }

  Future<bool> postScannedTags(BuildContext context) async {
    try {
      showLoading(context);

      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.productUnitVerificationUrl,
        body: unitVerifyModels[currentIndex].toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _removeProcessedProduct();
        showToast('Tags posted successfully');
        return true;
      } else {
        ErrorHandler.alertDialog(context, 'Failed to post tags');
        return false;
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
      return false;
    } finally {
      removeLoading(context);
    }
  }

  void _removeProcessedProduct() {
    productAvailabilityList.removeWhere(
      (e) => e.productId == unitVerifyModel?.product,
    );
    scannedUnits.removeWhere(
        (e) => e.split("-").first == unitVerifyModel?.product.toString());
    secondaryScannedUnits.removeWhere(
        (e) => e.split("-").first == unitVerifyModel?.product.toString());
    unitVerifyModels.removeAt(currentIndex);
    currentIndex--;
    unitVerifyModel = null;

    organizeProductsByRack();
    notifyListeners();
  }
}
