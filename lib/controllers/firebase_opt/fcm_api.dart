

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/constants/app_urls.dart';

class FCMApi {
  postFcmToken() async {
    try {
      final token = await  FirebaseMessaging.instance.getToken();
      final body = {
        "fcm_token": token
      };
      await DioClient().request(
        requestType: RequestType.postWithToken,
        body: body,
        url: AppUrls.fcmTokenUrl,
      );
    } catch (e) {
      print('Error posting fcm: $e');
    }
  }
}