import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/low_stock/model/carton_model.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class RackUpdateProvider extends ChangeNotifier {
  CartonModel? cartonModel;

  Future callCartonInfoApi(BuildContext context, String code) async {
    try {
      // debugger();
      if (!code.contains("carton")) {
        throw "Invalid Carton QR";
      }
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.cartonInfoUrl.replaceAll(':id', code),
      );
      log("Carton Info: ${response.statusCode}");

      if (response.statusCode == 200) {
        cartonModel = CartonModel.fromJson(response.data, code);
      }
      if (context.mounted) {
        Provider.of<ScanMessageProvider>(context, listen: false)
            .setMessage(context, "Scan Rack Code - Update Rack");
        navigateReplacement(context,
            route: NavigationConstants.rackUpdateScreenRoute,
            extra: {'productId': cartonModel?.productId});
      }
    } catch (e) {
      ErrorHandler.alertDialog(context, "Invalid QR Code ${detectQrMessage(code)}");
      return false;
    }
  }

  Future<bool> updateRack(
      BuildContext context, String code, int productId) async {
    try {
      if (!code.contains("rack")) {
        throw "Invalid Rack QR";
      }
      print("""
      url : ${AppUrls.updateRackUrl}
      body : {
          'rack_identifier': $code,
          'product_id': $productId,
        }""");
      final url = AppUrls.updateRackUrl;
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "rack_identifier": code,
          "product_id": productId,
        },
      );
      if (response.statusCode == 200 && context.mounted) {
        showToast("Rack updated successfully");
        navigateReplacement(context, route: NavigationConstants.dashboardRoute);
        return true;
      } else {
        ErrorHandler.alertDialog(context, 'Failed to update rack');
        return false;
      }
    } catch (ex) {
      ErrorHandler.alertDialog(context, ex.toString());
      return false;
    }
  }

  // get product id
  Future<bool> getProductId(BuildContext context, String code) async {
    try {
      final prodIdString = code.split("-").first;
      final productId = int.parse(prodIdString);
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Rack Code - Update Rack");
      navigateReplacement(context,
          route: NavigationConstants.rackUpdateScreenRoute,
          extra: {'productId': productId});
      return true;
    } catch (e) {
      ErrorHandler.alertDialog(context, "Invalid QR Code ${detectQrMessage(code)}");
      return false;
    }
  }
}
