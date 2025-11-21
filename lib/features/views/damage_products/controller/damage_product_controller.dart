
import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/damage_products/model/rack_product_model.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';

class DamageProductController extends ChangeNotifier {
  bool isLoading = false;
  List<String> tagList = [];
  List<String> difference = [];
  List<String> productUnits = [];
  String productName = 'Products';
  List<Product> rackProductList = [];
  int scanCount = 0;
  List<String> damageProducts = [];

  Future<void> postProductTag(String code) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.damageProductUnitUrl,
        body: {'tag': code},
      );

      if (response.data is List) {
        productUnits = (response.data as List)
            .map((item) => item['tag'].toString())
            .toList();

        productName = (response.data as List)
            .map((item) => item['product_name'].toString())
            .toList()
            .first;
      } else {
        productUnits = [];
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      showToast(e.toString());
    }
  }

  Future<void> markDamaged(List<String> code, BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.markDamageUrl,
        body: {"tags": code},
      );

      if (response.statusCode == 200) {
        reset();
        showToast("${response.data['message']}");
      } else {
        showToast("Failed to mark as damaged");
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      ShowAlertDialog(
        body: Text(e.toString()),
        okFunc: () {
          Navigator.pop(context);
        },
      ).showAlertDialog(context);
    }
  }

  Future<bool> getProductList(String code) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await DioClient().request(
          requestType: RequestType.postWithToken,
          url: AppUrls.scanRackDamageUrl,
          body: {'unique_identifier': code});

      if (response.statusCode == 200) {
        final productsResponse = ProductsResponse.fromJson(response.data);

        rackProductList = productsResponse.products;
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        rackProductList = [];
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      showToast("Failed to fetch product list");
      return false;
    }
  }

  bool setDamageProducts(String code, BuildContext context) {
    if (damageProducts.contains(code)) {
      ShowAlertDialog(
        body: Text("Tag already Scanned: $code"),
        okFunc: () {
          Navigator.pop(context);
        },
      ).showAlertDialog(context);
      return false;
    } else {
      damageProducts.add(code);
      notifyListeners();
      return true;
    }
  }

  //post product damage in mainStore
  Future<bool> productDamageRequest(String code) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await DioClient().request(
          requestType: RequestType.postWithToken,
          url: AppUrls.damageRequestUrl,
          body: {'tags': damageProducts, 'rack_identifier': code});

      if (response.statusCode == 200) {
        showToast("Products Posted Successfully");
        damageProducts = [];
        isLoading = false;

        return true;
      } else {
        damageProducts = [];
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      showToast("Failed to fetch product list");
      return false;
    }
  }

  void scannedTags(String code, BuildContext context) async {
    if (tagList.contains(code)) {
      await ShowAlertDialog(
        disableBackground: true,
        body: Text("Tag already scanned: $code"),
        okFunc: () {
          Navigator.pop(context);
        },
      ).showAlertDialog(context);

      return;
    }
    tagList.add(code);
    scanCount++;
    notifyListeners();
  }

  List<String> getUnscannedTags() {
    difference = productUnits.where((tag) => !tagList.contains(tag)).toList();
    notifyListeners();
    return difference;
  }

  void reset() {
    tagList.clear();
    scanCount = 0;
    productName = 'Products';
    productUnits.clear();
    notifyListeners();
  }

  void getMessageForNoQr(BuildContext context, bool scanRack, bool qr) {
    final message = scanRack
        ? "Scan the Rack to get the list of products"
        : (qr)
            ? (scanCount > 0)
                ? "Scanned $scanCount Products"
                : "Scan the Product to get the details"
            : (scanCount > 0)
                ? "Scanned $scanCount $productName"
                : "Scan the $productName to get the details";
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }
}
