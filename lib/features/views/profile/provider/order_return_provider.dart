import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/order/models/order_return_model.dart';

class OrderReturnProvider extends ChangeNotifier {

   OrderReturnModel returnOrder= ;
  Future<void> fetchOrderReturns() async {
    final response = await DioClient().request(
      url: AppUrls.orderReturnUrl,
      requestType: RequestType.getWithToken,
    );
    
    if (response.statusCode == 200) {
           returnOrder = data.map((order) => OrderNotification.fromJson(order)).toList();

      
    } else {
      throw Exception('Failed to load order returns');
    }

    notifyListeners();
  }
}
