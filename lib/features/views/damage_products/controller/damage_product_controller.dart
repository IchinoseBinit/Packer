import 'package:flutter/foundation.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/show_toast_message.dart';

class DamageProductController extends ChangeNotifier {
  bool isLoading = false;
  List<String> tagList = [];
  List<String> difference = [];
  List<String> productUnits = [];
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
      } else {
        productUnits = [];
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      showToast("...Failed...");
    }
  }

  Future<void> markDamaged(List<String> code) async {
    try {
      isLoading = true;
      notifyListeners();

      await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.markDamageUrl,
        body: {"tags": code},
      );

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      showToast("...Failed...");
    }
  }

  Future<void> requestQrDamaged(List<String> code) async {
    try {
      isLoading = true;
      notifyListeners();

      await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.qrDamageUrl,
        body: {"tags": code},
      );

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      showToast("...Failed...");
    }
  }

  void scannedTags(String code) {
    tagList.add(code);
  }

  List<String> getUnscannedTags() {
    difference = productUnits.where((tag) => !tagList.contains(tag)).toList();
    notifyListeners();
    return difference;
  }

  void reset() {
    tagList.clear();
    productUnits.clear();
    notifyListeners();
  }
}
