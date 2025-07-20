import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/order/models/order_return_model.dart';

class OrderReturnProvider extends ChangeNotifier {
  List<OrderReturnModel> returnOrder = <OrderReturnModel>[];

  Future<void> fetchOrderReturns() async {
    try {
      final response = await DioClient().request(
        url: AppUrls.orderReturnUrl,
        requestType: RequestType.getWithToken,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        returnOrder =
            data.map((order) => OrderReturnModel.fromJson(order)).toList();
      } else {
        throw Exception('Failed to load order returns');
      }
    } catch (e) {
      print('Error fetching order returns: $e');
      // Handle error appropriately, e.g., show a message to the user
    }

    notifyListeners();
  }
}
